#!/bin/bash
#Script to Analyze Server Performance Stats
#
#Goal of this project is to write a script to analyse server performance stats.
#Requirements
#You are required to write a script server-stats.sh that can analyse basic server performance stats. You should be able to run the script on any Linux server and it should give you the following stats:
#Total CPU usage - Done
#Total memory usage (Free vs Used including percentage)
#Total disk usage (Free vs Used including percentage)
#Top 5 processes by CPU usage
#Top 5 processes by memory usage
#Stretch goal: Feel free to optionally add more stats such as os version, uptime, load average, logged in users, failed login attempts etc.
#
#Author: Carlos Gonzalez

#Here's the framework for every script you write:
#Ask yourself these 4 questions before writing one line:
#
#What is the input? (a file, a command output, a user argument?)
#What do I need to do with it? (filter, count, format, compress?)
#What is the output? (print to screen, write to file, both?)
#What commands give me that data? (then pipe and parse)

#Total CPU usage
function get_cpu_usage() {
    idle_cpu=$(mpstat | awk '{print $13}' | tail -n 1)
    cpu_usage=$(echo "100 - $idle_cpu" | bc)
    echo "$cpu_usage%"
}

#Total Memory Usage
function get_memory_usage() {
    used_mem=$(free -h | awk '{print $2}' | head -n 2 | tail -n 1)
    free_mem=$(free -h | awk '{print $3}' | head -n 2 | tail -n 1)
    total_mem=$(( used_mem + free_mem ))
    used_mem_percentage=$(echo "scale=2;100 * $used_mem / $total_mem" | bc)
    echo "$used_mem_percentage%"
}

#Total Disk Usage
function get_disk_usage() {
    total_disk=$(df -BG --output=size / | tail -n 1| tr -d 'G ')
    usage_disk=$(df -BG --output=used / | tail -n 1| tr -d 'G ')
    free_disk=$(df -BG --output=avail / | tail -n 1| tr -d 'G ')
    disk_usage_percentage_on_system=$(df -h --output=pcent / | tail -n 1)
    echo "$disk_usage_percentage_on_system%"
    echo "----------------|----------------|----------------|"
    echo "|Total Disk     | Total usage     | Total Free     |"
    echo "|----------------|----------------|----------------|"
    echo "| $total_disk GB | $usage_disk GB  | $free_disk GB  |"
    echo "|----------------|----------------|----------------|"
    echo "|              Usage Percentage                    |"
    echo "|----------------|----------------|----------------|"
    echo "| $disk_usage_percentage_on_system                 |"
}





function show_stats() {
    echo "Server Performance Stats"
    echo "------------------------"
    get_cpu_usage
    get_memory_usage
    get_disk_usage
}




echo "|----------------|----------------|----------------|"
echo "| Total CPU Usage | Total Memory Usage | Total Disk Usage |"
echo "|----------------|----------------|----------------|"
echo "| $(get_cpu_usage) | $(get_memory_usage) | $(get_disk_usage) |"




