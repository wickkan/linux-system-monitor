#!/bin/bash

# System Monitor for Linux - Configuration-driven monitoring tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config_parser.sh"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/process_monitor.sh"

validate_config
load_config

echo "========================================"
echo "    System Monitor - Linux Edition"
echo "========================================"
if [ "$SHOW_TIMESTAMP" = "true" ]; then
    date
fi
print_config
echo "========================================"
echo ""

check_alarm() {
    local type=$1
    local value=$2
    local threshold_var_name="${type}_THRESHOLD"
    local threshold_limit=${!threshold_var_name}
    local int_value=$(printf "%.0f" "$value")

    local RED=""
    local GREEN=""
    local RESET=""
    if [ "$COLORS_ENABLED" = "true" ]; then
        RED="\033[0;31m"
        GREEN="\033[0;32m"
        RESET="\033[0m"
    fi

    if [ "$int_value" -gt "$threshold_limit" ]; then
        echo -e "${RED}[ALARM]${RESET} ${type} threshold exceeded! Current: ${value}%, Limit: ${threshold_limit}%"
    else
        echo -e "${GREEN}[OK]${RESET} ${type} usage: ${value}%"
    fi
}

echo "Starting System Monitor... Press [CTRL+C] to stop."
echo "Monitoring interval: ${MONITORING_INTERVAL} seconds"
echo "-----------------------------------------------"

mkdir -p "${LOG_DIR}/linux"

while true; do
    current_cpu="N/A"
    current_mem="N/A"
    current_disk="N/A"
    top_processes=""

    if [ "$ENABLE_CPU" = "true" ]; then
        current_cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
        check_alarm "CPU" "$current_cpu"
    fi

    if [ "$ENABLE_MEMORY" = "true" ]; then
        current_mem=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
        check_alarm "MEMORY" "$current_mem"
    fi

    if [ "$ENABLE_DISK" = "true" ]; then
        current_disk=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
        check_alarm "DISK" "$current_disk"
    fi

    if [ "$ENABLE_PROCESSES" = "true" ]; then
        top_processes=$(get_top_processes "$PROCESS_TOP_COUNT" "linux")
        format_processes_human "$top_processes"
    fi

    if [ "$LOGGING_ENABLED" = "true" ]; then
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        log_metrics "$timestamp" "$current_cpu" "$current_mem" "$current_disk" "linux" "$top_processes"
    fi

    echo "-----------------------------------------------"
    sleep "$MONITORING_INTERVAL"
done
