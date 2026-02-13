#!/bin/bash

# Multi-Format Logger Library
# Supports human-readable, JSON, and CSV output formats

log_human() {
    local timestamp=$1
    local cpu=$2
    local memory=$3
    local disk=$4
    local platform=$5
    local processes=$6

    local log_file="${LOG_DIR}/${platform}/resource_usage.log"
    local log_line="${timestamp} | CPU ${cpu}% | MEMORY ${memory}% | DISK ${disk}%"

    if [ -n "$processes" ] && [ "$ENABLE_PROCESSES" = "true" ]; then
        local process_summary=$(echo "$processes" | head -n 1 | awk '{print $4}')
        log_line="${log_line} | TOP: ${process_summary}"
    fi

    echo "$log_line" >> "$log_file"
}

log_json() {
    local timestamp=$1
    local cpu=$2
    local memory=$3
    local disk=$4
    local platform=$5
    local processes=$6

    local log_file="${LOG_DIR}/${platform}/metrics.jsonl"
    local iso_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "$timestamp")

    # Build process array for JSON
    local process_json="[]"
    if [ -n "$processes" ] && [ "$ENABLE_PROCESSES" = "true" ]; then
        local first=true
        local temp_json=""

        while IFS= read -r line; do
            [ -z "$line" ] && continue

            local pid=$(echo "$line" | awk '{print $1}')
            local cpu_p=$(echo "$line" | awk '{print $2}')
            local mem_p=$(echo "$line" | awk '{print $3}')
            local cmd=$(echo "$line" | awk '{for(i=4;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}' | sed 's/"/\\"/g')

            if [ "$first" = true ]; then
                temp_json="{\"pid\":${pid},\"cpu\":${cpu_p},\"mem\":${mem_p},\"command\":\"${cmd}\"}"
                first=false
            else
                temp_json="${temp_json},{\"pid\":${pid},\"cpu\":${cpu_p},\"mem\":${mem_p},\"command\":\"${cmd}\"}"
            fi
        done <<< "$processes"

        process_json="[${temp_json}]"
    fi

    local json="{\"timestamp\":\"${iso_timestamp}\",\"platform\":\"${platform}\",\"metrics\":{\"cpu\":${cpu},\"memory\":${memory},\"disk\":${disk}},\"top_processes\":${process_json}}"

    echo "$json" >> "$log_file"
}

log_csv() {
    local timestamp=$1
    local cpu=$2
    local memory=$3
    local disk=$4
    local platform=$5
    local processes=$6

    local log_file="${LOG_DIR}/${platform}/metrics.csv"

    # Create CSV header if file doesn't exist
    if [ ! -f "$log_file" ]; then
        echo "timestamp,platform,cpu_percent,memory_percent,disk_percent,top_process" > "$log_file"
    fi

    # Get top process name for CSV
    local top_process=""
    if [ -n "$processes" ] && [ "$ENABLE_PROCESSES" = "true" ]; then
        top_process=$(echo "$processes" | head -n 1 | awk '{print $4}')
    fi

    # Append data row
    echo "${timestamp},${platform},${cpu},${memory},${disk},${top_process}" >> "$log_file"
}

log_metrics() {
    local timestamp=$1
    local cpu=$2
    local memory=$3
    local disk=$4
    local platform=$5
    local processes=$6

    # Get logging format preferences from config
    local enable_human=$(get_config_value ".logging.formats.human_readable" "true")
    local enable_json=$(get_config_value ".logging.formats.json" "false")
    local enable_csv=$(get_config_value ".logging.formats.csv" "false")

    # Log to enabled formats
    if [ "$enable_human" = "true" ]; then
        log_human "$timestamp" "$cpu" "$memory" "$disk" "$platform" "$processes"
    fi

    if [ "$enable_json" = "true" ]; then
        log_json "$timestamp" "$cpu" "$memory" "$disk" "$platform" "$processes"
    fi

    if [ "$enable_csv" = "true" ]; then
        log_csv "$timestamp" "$cpu" "$memory" "$disk" "$platform" "$processes"
    fi
}
