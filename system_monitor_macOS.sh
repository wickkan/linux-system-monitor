#!/bin/bash

# System Monitor for macOS - Configuration-driven monitoring tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config_parser.sh"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/process_monitor.sh"

validate_config
load_config

echo "========================================"
echo "    System Monitor - macOS Edition"
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
    local int_value=$(printf "%.0f" "$value" 2>/dev/null || echo 0)

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

mkdir -p "${LOG_DIR}/macOS"

while true; do
    current_cpu="N/A"
    current_mem="N/A"
    current_disk="N/A"
    top_processes=""

    if [ "$ENABLE_CPU" = "true" ]; then
        idle_cpu=$(top -l 1 | grep "CPU usage" | awk '{print $7}' | sed 's/%//')
        current_cpu=$(echo "100 - $idle_cpu" | bc 2>/dev/null || awk "BEGIN {print 100 - $idle_cpu}")
        check_alarm "CPU" "$current_cpu"
    fi

    if [ "$ENABLE_MEMORY" = "true" ]; then
        free_mem=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//')
        current_mem=$(echo "100 - $free_mem" | bc 2>/dev/null || awk "BEGIN {print 100 - $free_mem}")
        check_alarm "MEMORY" "$current_mem"
    fi

    if [ "$ENABLE_DISK" = "true" ]; then
        current_disk=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
        check_alarm "DISK" "$current_disk"
    fi

    if [ "$ENABLE_PROCESSES" = "true" ]; then
        top_processes=$(get_top_processes "$PROCESS_TOP_COUNT" "macOS")
        format_processes_human "$top_processes"
    fi

    if [ "$LOGGING_ENABLED" = "true" ]; then
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        log_metrics "$timestamp" "$current_cpu" "$current_mem" "$current_disk" "macOS" "$top_processes"
    fi

    echo "-----------------------------------------------"
    sleep "$MONITORING_INTERVAL"
done
