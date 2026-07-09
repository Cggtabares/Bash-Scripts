#!/bin/bash
#In this project, you will build a tool to archive logs on a set schedule by compressing them and storing them in a new directory, this is especially useful for removing old logs and keeping the system clean while maintaining the logs in a compressed format for future reference. This project will help you practice your programming skills, including working with files and directories, and building a simple cli tool.#
#The most common location for logs on a unix based system is /var/log.
#
#Requirements
#The tool should run from the command line, accept the log directory as an argument, compress the logs, and store them in a new directory. The user should be able to:
#
#Provide the log directory as an argument when running the tool.
#log-archive <log-directory>
#The tool should compress the logs in a tar.gz file and store them in a new directory.
#
#The tool should log the date and time of the archive to a file.
#logs_archive_20240816_100648.tar.gz


arg_1=$1

function run_log_archive(){
    arg_variable=$arg_1

    while true; do
        is_log_directory_provided $arg_variable
        echo "Archiving logs from $arg_variable"
        is_archive_directory_created $(dirname $arg_variable)/archive
        tar -czf $(dirname $arg_variable)/archive/logs_archive_$(date +%Y%m%d_%H%M%S).tar.gz $arg_variable
        echo "Logs archived successfully."
        rm -rf $arg_variable/*
        echo "Logs deleted from original directory."
        sleep 5
    done
}

function is_archive_directory_created(){
    if [ ! -d "$arg_1" ]; then
        mkdir -p "$arg_1"
        echo "Archive directory created at $arg_1"
    else
        echo "Archive directory already exists at $arg_1"
    fi

}


function is_log_directory_provided(){
    if [ -z "$arg_1" ]; then
        echo "Error: Log directory not provided."
        echo "Usage: log-archive <log-directory>"
        exit 1
    fi

    if [ ! -d "$arg_1" ]; then
        echo "Error: Log directory $arg_1 does not exist."
        exit 1
    fi
}

run_log_archive