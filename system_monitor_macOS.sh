#!/bin/bash

# System Monitor for macOS - Configuration-driven monitoring tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config_parser.sh"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/process_monitor.sh"
source "${SCRIPT_DIR}/lib/network_monitor.sh"
source "${SCRIPT_DIR}/lib/service_monitor.sh"
source "${SCRIPT_DIR}/lib/advanced_metrics.sh"

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
    network_data=""
    service_data=""
    advanced_data=""

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

    # Network monitoring
    if [ "$ENABLE_NETWORK" = "true" ]; then
        echo "  Network Monitoring:"
        IFS=',' read -ra INTERFACES <<< "$NETWORK_INTERFACES"
        network_summary=""
        for iface in "${INTERFACES[@]}"; do
            iface=$(echo "$iface" | xargs) # trim whitespace
            stats=$(get_network_stats "$iface" "macOS")
            summary=$(format_network_summary "$iface" "$stats" "")
            echo "    [$iface] $summary"
            network_summary="${network_summary}${iface}:${summary};"
        done
        if [ "$NETWORK_TRACK_CONNECTIONS" = "true" ]; then
            connections=$(get_connection_count "macOS")
            echo "    Connections: TCP/UDP/EST: $connections"
            network_data="{\"interfaces\":\"${NETWORK_INTERFACES}\",\"connections\":\"${connections}\"}"
        else
            network_data="{\"interfaces\":\"${NETWORK_INTERFACES}\"}"
        fi
    fi

    # Service monitoring
    if [ "$ENABLE_SERVICES" = "true" ]; then
        echo "  Service Health:"
        services_down=0
        if [ -n "$SERVICES_TO_MONITOR" ]; then
            IFS=',' read -ra SERVICES <<< "$SERVICES_TO_MONITOR"
            for svc in "${SERVICES[@]}"; do
                svc=$(echo "$svc" | xargs) # trim whitespace
                status=$(check_service_status "$svc" "macOS")
                format_service_status "$svc" "$status"
                state=$(echo "$status" | cut -d'|' -f1)
                if [ "$state" != "running" ] && [ "$state" != "active" ]; then
                    ((services_down++))
                fi
            done
        fi
        if [ -n "$PROCESSES_TO_MONITOR" ]; then
            IFS=',' read -ra PROCS <<< "$PROCESSES_TO_MONITOR"
            for proc in "${PROCS[@]}"; do
                proc=$(echo "$proc" | xargs) # trim whitespace
                status=$(check_process_running "$proc")
                format_process_status "$proc" "$status"
            done
        fi
        service_data="{\"services\":\"${SERVICES_TO_MONITOR}\",\"processes\":\"${PROCESSES_TO_MONITOR}\",\"down\":${services_down}}"
    fi

    # Advanced metrics
    if [ "$ENABLE_ADVANCED" = "true" ]; then
        echo "  Advanced Metrics:"
        load_avg=""
        swap_stats=""
        disk_io=""
        temp=""

        if [ "$TRACK_LOAD_AVERAGE" = "true" ]; then
            load_avg=$(get_load_average "macOS")
            echo "    Load Average: $(format_load_average "$load_avg")"
            load_1m=$(echo "$load_avg" | awk '{print $1}')
            # Check threshold for 1-minute load average
            if command -v bc >/dev/null 2>&1; then
                threshold_check=$(echo "$load_1m > $LOAD_THRESHOLD_1M" | bc -l 2>/dev/null)
                if [ -n "$threshold_check" ] && [ "$threshold_check" -eq 1 ] 2>/dev/null; then
                    echo "    [ALARM] Load average 1m ($load_1m) exceeds threshold ($LOAD_THRESHOLD_1M)"
                fi
            fi
        fi

        if [ "$TRACK_SWAP" = "true" ]; then
            swap_stats=$(get_swap_stats "macOS")
            echo "    Swap Usage: $(format_swap_stats "$swap_stats")"
            swap_percent=$(echo "$swap_stats" | awk '{print $3}')
            if [ "$swap_percent" != "N/A" ] && [ -n "$swap_percent" ] && [ "$swap_percent" != "0" ]; then
                check_alarm "SWAP" "$swap_percent"
            fi
        fi

        if [ "$TRACK_DISK_IO" = "true" ]; then
            disk_io=$(get_disk_io_stats "macOS")
            echo "    Disk I/O: $(format_disk_io "$disk_io")"
        fi

        if [ "$TRACK_TEMPERATURE" = "true" ]; then
            temp=$(get_temperature_stats "macOS")
            if [ "$temp" != "N/A" ]; then
                echo "    Temperature: ${temp}°C"
                temp_int=$(printf "%.0f" "$temp" 2>/dev/null || echo "0")
                if [ "$temp_int" -gt "$TEMP_THRESHOLD" ] 2>/dev/null; then
                    echo "    [ALARM] Temperature ($temp°C) exceeds threshold ($TEMP_THRESHOLD°C)"
                fi
            else
                echo "    Temperature: N/A (install osx-cpu-temp)"
            fi
        fi

        advanced_data="{\"load\":\"${load_avg}\",\"swap\":\"${swap_stats}\",\"io\":\"${disk_io}\",\"temp\":\"${temp}\"}"
    fi

    if [ "$LOGGING_ENABLED" = "true" ]; then
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        log_metrics "$timestamp" "$current_cpu" "$current_mem" "$current_disk" "macOS" "$top_processes" "$network_data" "$service_data" "$advanced_data"
    fi

    echo "-----------------------------------------------"
    sleep "$MONITORING_INTERVAL"
done
