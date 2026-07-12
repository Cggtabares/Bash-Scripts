#!/bin/bash

# Requirements
# The tool should run from the command line, accept the log directory as an argument, compress the logs, and store them in a new directory. The user should be able to:
# Provide the log directory as an argument when running the tool.

# log-archive <log-directory>
# The tool should compress the logs in a tar.gz file and store them in a new directory.

# The tool should log the date and time of the archive to a file.
# logs_archive_20240816_100648.

arg_1=$1

function run_log_archive(){
    arg_variable=$arg_1

    while true; do
        is_log_directory_provided "$arg_variable"
        echo "Archiving logs from directory: $arg_variable"
        is_archive_directory_created $(dirname "$arg_variable")/archive
        #tar -czf /var/log/nginx/logs/$(date +%Y-%m-%d)_$(date +%H-%M-%S)logs.tar.gz "$arg_variable"/*.log
        mv /var/log/nginx/logs/$(date +%Y-%m-%d)_$(date +%H-%M-%S)logs.tar.gz /var/log/nginx/archive/
        #echo "Logs archived successfully."
        #sleep 60
    done

}

function is_archive_directory_created() {
    if ([ -z "$(find "$arg_variable" -type f -name "*.log" | grep -q .)" ]); then
        echo "Found Log files"
        if ([ ! -d "$1" ]); then
            echo "Archive directory does not exist. Creating archive directory."
            #mkdir -p "$1"
            exit 1
        fi

    else
        echo "Log files cannot be found in directory $arg_variable."
        exit 1
    fi
}

function is_log_directory_provided() {
    if ([ -z "$arg_variable" ]); then
        echo "Log directory not provided. Please provide the log directory as an argument."
        exit 1
    fi
}


run_log_archive