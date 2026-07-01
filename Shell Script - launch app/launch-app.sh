#!/bin/bash
#Script to launch an ecommerce
#https://github.com/kodekloudhub/learning-app-ecommerce.git 
#This APP works with a LAMP (Linux Apache MariaDB PHP) stack
#Script to install on 1 VM, specifically CENTos
#Author: Carlos Gonzalez

###Functions###



###Checking if the service is active
function check_service(){
    service_name=$(sudo systemctl is-active $1)

    if [ $service_name = "active" ]
    then
        echo "$1 service is running"
    else
        echo "$1 service is not running"
        exit 1
    fi
}

###Checking if the port is open 
function check_port(){
    port_status=$(sudo firewall-cmd --list-all --zone=public | grep ports)

    if [[ $port_status == *$1* ]]
    then
        echo "Port $1 is open"
    else
        echo "Port $1 is not open"
        exit 1
    fi
}


#Deploy Pre-Requisites
echo "Installing Pre-Requisites"
sudo yum install -y firewalld
sleep 3
sudo systemctl start firewalld
sudo systemctl enable firewalld

#Deploy and Configure Database

#1 Install MariaDB
echo "Installing MariaDB"
sudo yum install -y mariadb-server
sleep 3
#sudo vi /etc/my.cnf #if you want to change the port, access to this file and configure it with the new port
sudo systemctl start mariadb
sudo systemctl enable mariadb
check_service mariadb

#2 Configure firewall for Database
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

#3 Configure Database
echo "Configuring Database"
cat > db-config-script.sql <<-EOF
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;
EOF
#ON a multi-node setup remember to provide the IP address of the web server here: 'ecomuser'@'web-server-ip'
sudo mysql < db-config-script.sql


#4 Load Product Inventory Information database
echo "Loading Product Inventory Information"
##Create the db-load-script.sql
cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF

##Run SQL Script
sudo mysql < db-load-script.sql

#Deploy and Configure Web

echo "Deploying and Configuring Web Server"
#1 Install required packages and configure Firewall
sudo yum install -y httpd php php-mysqlnd
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload
check_port 80

#2 Configure httpd
#Change DirectoryIndex index.html to DirectoryIndex index.php to make the php page the default page
sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

#3 Start httpd
sudo systemctl start httpd
sudo systemctl enable httpd

#4 Download code
sudo yum install -y git
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/

#4.1 Change ip address
sudo sed -i 's#// \(.*mysqli_connect.*\)#\1#' /var/www/html/index.php
sudo sed -i 's#// \(\$link = mysqli_connect(.*172\.20\.1\.101.*\)#\1#; s#^\(\s*\)\(\$link = mysqli_connect(\$dbHost, \$dbUser, \$dbPassword, \$dbName);\)#\1// \2#' /var/www/html/index.php

sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php

#5 Create and configure the .env file
#Create an .env file in the root of your project folder.
sudo tee /var/www/html/.env > /dev/null <<EOF
DB_HOST=localhost
DB_USER=ecomuser
DB_PASSWORD=ecompassword
DB_NAME=ecomdb
EOF
#Normally this step is not showing on Script since it shows sensitive info but this is a learning Script.


