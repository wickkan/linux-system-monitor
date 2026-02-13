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

    # Convert decimal to integer by rounding
    local int_value=$(printf "%.0f" "$value")

    # Use standard Bash integer comparison
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
    # Get CPU usage (Linux style: 100 - idle)
    current_cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')

    # Get Memory usage % (Linux style: used/total)
    current_mem=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

    # Get Disk usage % for root directory
    current_disk=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

    # 4. Calls (Now matching the function name above)
    check_alarm "CPU" "$current_cpu"
    check_alarm "MEMORY" "$current_mem"
    check_alarm "DISK" "$current_disk"

    echo "-----------------------------------------------"

    sleep 5
done