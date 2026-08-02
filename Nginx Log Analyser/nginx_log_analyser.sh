#!/bin/bash

# Nginx Log Analyser
# Usage: ./nginx_log_analyser.sh [path/to/nginx_access.log]
# If no argument is given, the script uses ./nginx_access.log

LOG_FILE="${1:-./nginx_access.log}"

if [ ! -f "$LOG_FILE" ]; then
  echo "Error: log file '$LOG_FILE' not found." >&2
  echo "Usage: $0 [path/to/nginx_access.log]" >&2
  exit 1
fi

# Helper: show a header
print_header() {
  printf "%s\n" "=============================="
  printf "%s\n" "$1"
  printf "%s\n" "=============================="
}

# Top 5 IP addresses with the number of requests made to the server (IP COUNT)
print_header "Top 5 IP addresses with the most requests"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 5 | awk '{printf "%-20s %s\n", $2, $1}'
printf "\n"

# Top 5 most requested paths (PATH COUNT)
print_header "Top 5 most requested paths"
# field 7 is usually the request path in a common log format
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 5 | awk '{printf "%-40s %s\n", $2, $1}'
printf "\n"

# Top 5 most requested status codes (STATUS COUNT)
print_header "Top 5 most requested status codes"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 5 | awk '{printf "%-6s %s\n", $2, $1}'
printf "\n"

# End
#Author: Carlos Gonzalez Tabares
