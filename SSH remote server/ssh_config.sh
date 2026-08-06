#!/bin/bash

#SSH remote server
#This script will connect to a remote server via SSH and execute a command

echo "This script will connect to a remote server via SSH and execute a command."

read -p "Enter the remote server IP address: " remote_server
read -p "Enter the username: " username
read -s -p "Enter the remote server password: " remote_password
read -p "Enter the path to the public key file (e.g., ~/.ssh/id_rsa.pub): " public_key_file

###
#script that will create the keys, copy the keys with sshpass, and config sshd_config to disable password authentication and root login, and enable fail2ban
#Let's make it concrete. Here's exactly what happens, step by step, when you run:

#Only for Ubuntu systems (for now)
if [ "$(dpkg -l | grep sshpass)" ]; then
    echo "sshpass is already installed."
else
    echo "sshpass is not installed. Installing..."
    sudo apt-get update && sudo apt-get install -y sshpass
fi

#./ssh-server-setup.sh carlos 192.168.1.50 ~/.ssh/id_ed25519.pub
# Configuration
KEY_TYPE="ed25519"
KEY_DIR="$HOME/.ssh"
KEY_PATH="$KEY_DIR/id_ed25519"
REMOTE_PASSWD="$remote_password"
COMMENT="$(whoami)@$(hostname)-$(date +%F)"

# Expand leading ~/ in the provided public key path so bash can read it correctly.
public_key_file="${public_key_file/#\~/$HOME}"


if [ -z "$public_key_file" ]; then
    # 1. Create directory with correct permissions if it doesn't exist
    if [ ! -d "$KEY_DIR" ]; then
        mkdir -p "$KEY_DIR"
        chmod 700 "$KEY_DIR"
    fi

# 2. Generate the key pair safely
    if [ -f "$KEY_PATH" ]; then
        echo "Warning: Key already exists at $KEY_PATH. Skipping generation to prevent overwrite."
    else
        echo "Generating a new $KEY_TYPE SSH key..."
        ssh-keygen -t "$KEY_TYPE" -f "$KEY_PATH" -N "" -C "$COMMENT" -q
    
        # Set strict file permissions for the private key
        chmod 600 "$KEY_PATH"
        echo "Success! Key pair created at $KEY_PATH"
    fi
    public_key_file="$KEY_PATH.pub"
else
    # Derive the corresponding private key for the supplied public key file.
    KEY_PATH="${public_key_file%.pub}"
fi

#Step 1 — Push the key
#The script takes your local public key file and sends it to the remote server, appending it into that user's ~/.ssh/authorized_keys on the remote box. This is one ssh/scp command run from your laptop, targeting the remote host.

if ! sshpass -p "$REMOTE_PASSWD" ssh-copy-id -i "$public_key_file" -o StrictHostKeyChecking=no "$username@$remote_server"; then
    echo "Failed to copy SSH key to the remote server. Please verify the username, host, and password."
    exit 1
fi

#Step 2 — Verify the key works
#Before touching anything else, the script tests that you can now log in with the key alone — e.g. by running a harmless command remotely using ssh -i <key> user@host "echo test" and checking it succeeds without a password prompt. If this fails, the script stops here. Nothing risky happens yet.

if ssh -i "$KEY_PATH" "$username@$remote_server" "echo 'Key authentication successful!'"; then
    echo "Key authentication verified. Proceeding to harden SSH configuration."
else
    echo "Key authentication failed. Please check your key and try again."
    exit 1
fi  

#Step 3 — Harden sshd_config on the remote box
#Now that key auth is confirmed working, the script connects again and edits /etc/ssh/sshd_config on the remote server (via a remote command, e.g. ssh user@host "sudo sed -i ... /etc/ssh/sshd_config"):

#Set PermitRootLogin no
#Set PasswordAuthentication no

ssh -i "$KEY_PATH" "$username@$remote_server" "sudo sed -i -E 's/^[[:space:]]*#?[[:space:]]*PermitRootLogin[[:space:]]+.*/PermitRootLogin no/' /etc/ssh/sshd_config"
ssh -i "$KEY_PATH" "$username@$remote_server" "sudo sed -i -E 's/^[[:space:]]*#?[[:space:]]*PasswordAuthentication[[:space:]]+.*/PasswordAuthentication no/' /etc/ssh/sshd_config"

#Step 4 — Validate before restarting
#Still on the remote box, run sshd -t to check the edited config is syntactically valid. If it's broken, stop — do not restart sshd with a bad config, or you lose remote access entirely.

if ssh -i "$KEY_PATH" "$username@$remote_server" "sudo sshd -t"; then
    echo "sshd_config validation passed. Proceeding to restart sshd."
else
    echo "sshd_config validation failed. Please check the configuration on the remote server."
    exit 1
fi

#Step 5 — Restart sshd and confirm
#If validation passed, restart the sshd service remotely and confirm it's active (reusing your service-check pattern).

if ssh -i "$KEY_PATH" "$username@$remote_server" "sudo systemctl restart ssh && sudo systemctl is-active --quiet ssh"; then
    echo "SSH service restarted successfully and is active."
else
    echo "Failed to restart the SSH service or it is not active. Please check the remote server."
    exit 1
fi

#Step 6 — Install and start fail2ban
#Same remote-command pattern: check if fail2ban is installed, install if not, enable + start it, confirm it's running.

ssh -i "$KEY_PATH" "$username@$remote_server" "sudo apt-get update && sudo apt-get install -y fail2ban"

#End state: you can only get into that server via SSH key (no root login, no password login), and fail2ban is watching for brute-force attempts.

#The core mental model to hold onto: almost every "action" in this script is really just ssh user@host "<some command>" — your script from your laptop is a wrapper that fires off a sequence of remote commands, checking the result after each one before moving to the next. Nothing runs locally except the initial key transfer.

###