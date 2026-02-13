#!/bin/bash

# Threshold Definitions
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80

echo "------System Health Check------"
date
echo "-------------------------------"

# alarm function
check_alarm() {
    local type=$1
    local value=$2
    local threshold_var_name="${type}_THRESHOLD"
    local threshold_limit=${!threshold_var_name}

    # Convert decimal to integer by rounding (works on macOS/zsh/bash)
    local int_value=$(printf "%.0f" "$value" 2>/dev/null || echo 0)

    if [ "$int_value" -gt "$threshold_limit" ]; then
        echo -e "\033[0;31m[ALARM]\033[0m ${type} threshold exceeded! Current: ${value}%, Limit: ${threshold_limit}%"
    else
        echo -e "\033[0;32m[OK]\033[0m ${type} usage: ${value}%"
    fi
}

# system monitoring
echo "Starting System Monitor... Press [CTRL+C] to stop."
echo "-----------------------------------------------"

while true; do
    # macOS CPU usage 
    # Grab the 'idle' percentage and subtract from 100
    idle_cpu=$(top -l 1 | grep "CPU usage" | awk '{print $7}' | sed 's/%//')
    current_cpu=$(echo "100 - $idle_cpu" | bc 2>/dev/null || awk "BEGIN {print 100 - $idle_cpu}")

    # macOS Memory usage
    # memory_pressure provides a 'free' percentage; we subtract from 100
    free_mem=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//')
    current_mem=$(echo "100 - $free_mem" | bc 2>/dev/null || awk "BEGIN {print 100 - $free_mem}")

    # 3. Disk usage (df works on both, but awk needs a slight adjustment for macOS output)
    current_disk=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    # 4. Calls
    check_alarm "CPU" "$current_cpu"
    check_alarm "MEMORY" "$current_mem"
    check_alarm "DISK" "$current_disk"

    echo "-----------------------------------------------"

    sleep 5
done