#!/bin/bash

# =============================================================================
# System Monitor for macOS
# =============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load the configuration parser library
source "${SCRIPT_DIR}/lib/config_parser.sh"

# Validate and load configuration
# This replaces the hardcoded threshold definitions
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

# =============================================================================
# Function: check_alarm
# =============================================================================

check_alarm() {
    local type=$1
    local value=$2
    local threshold_var_name="${type}_THRESHOLD"
    local threshold_limit=${!threshold_var_name}

    # Convert decimal to integer by rounding (works on macOS/zsh/bash)
    local int_value=$(printf "%.0f" "$value" 2>/dev/null || echo 0)

    # Set color codes based on config
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

# =============================================================================
# Main Monitoring Loop
# =============================================================================

echo "Starting System Monitor... Press [CTRL+C] to stop."
echo "Monitoring interval: ${MONITORING_INTERVAL} seconds"
echo "-----------------------------------------------"

# Create log directory if it doesn't exist
mkdir -p "${LOG_DIR}/macOS"

while true; do
    # Initialize variables (in case metrics are disabled)
    current_cpu="N/A"
    current_mem="N/A"
    current_disk="N/A"

    # -----------------------------------------------------------------
    # CPU MONITORING
    # -----------------------------------------------------------------
    # Only run if enabled in config
    if [ "$ENABLE_CPU" = "true" ]; then
        # macOS CPU usage: grab 'idle' percentage and subtract from 100
        idle_cpu=$(top -l 1 | grep "CPU usage" | awk '{print $7}' | sed 's/%//')
        current_cpu=$(echo "100 - $idle_cpu" | bc 2>/dev/null || awk "BEGIN {print 100 - $idle_cpu}")
        check_alarm "CPU" "$current_cpu"
    fi

    # -----------------------------------------------------------------
    # MEMORY MONITORING
    # -----------------------------------------------------------------
    if [ "$ENABLE_MEMORY" = "true" ]; then
        # macOS Memory usage: memory_pressure provides 'free' %, we subtract from 100
        free_mem=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//')
        current_mem=$(echo "100 - $free_mem" | bc 2>/dev/null || awk "BEGIN {print 100 - $free_mem}")
        check_alarm "MEMORY" "$current_mem"
    fi

    # -----------------------------------------------------------------
    # DISK MONITORING
    # -----------------------------------------------------------------
    if [ "$ENABLE_DISK" = "true" ]; then
        # Disk usage for root directory
        current_disk=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
        check_alarm "DISK" "$current_disk"
    fi

    # -----------------------------------------------------------------
    # LOGGING
    # -----------------------------------------------------------------
    # Only log if enabled in config
    if [ "$LOGGING_ENABLED" = "true" ]; then
        log="$(date "+%Y-%m-%d %H:%M:%S") | CPU ${current_cpu}% | MEMORY ${current_mem}% | DISK ${current_disk}%"
        echo "$log" >> "${LOG_DIR}/macOS/resource_usage.log"
    fi

    echo "-----------------------------------------------"

    # Sleep for the configured interval
    # This makes the monitoring frequency configurable
    sleep "$MONITORING_INTERVAL"
done
