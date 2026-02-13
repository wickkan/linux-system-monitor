#!/bin/bash

# Multi-Format Logger Library
# Supports human-readable, JSON, and CSV output formats

log_human() {
    local timestamp=$1
    local cpu=$2
    local memory=$3
    local disk=$4
    local platform=$5

    local log_file="${LOG_DIR}/${platform}/resource_usage.log"
    echo "${timestamp} | CPU ${cpu}% | MEMORY ${memory}% | DISK ${disk}%" >> "$log_file"
}

log_json() {
    local timestamp=$1
    local cpu=$2
    local memory=$3
    local disk=$4
    local platform=$5

    local log_file="${LOG_DIR}/${platform}/metrics.jsonl"

    # Convert timestamp to ISO 8601 format for JSON
    local iso_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "$timestamp")

    # Build JSON object
    local json=$(cat <<EOF
{"timestamp":"${iso_timestamp}","platform":"${platform}","metrics":{"cpu":${cpu},"memory":${memory},"disk":${disk}}}
EOF
    )

    echo "$json" >> "$log_file"
}

log_csv() {
    local timestamp=$1
    local cpu=$2
    local memory=$3
    local disk=$4
    local platform=$5

    local log_file="${LOG_DIR}/${platform}/metrics.csv"

    # Create CSV header if file doesn't exist
    if [ ! -f "$log_file" ]; then
        echo "timestamp,platform,cpu_percent,memory_percent,disk_percent" > "$log_file"
    fi

    # Append data row
    echo "${timestamp},${platform},${cpu},${memory},${disk}" >> "$log_file"
}

log_metrics() {
    local timestamp=$1
    local cpu=$2
    local memory=$3
    local disk=$4
    local platform=$5

    # Get logging format preferences from config
    local enable_human=$(get_config_value ".logging.formats.human_readable" "true")
    local enable_json=$(get_config_value ".logging.formats.json" "false")
    local enable_csv=$(get_config_value ".logging.formats.csv" "false")

    # Log to enabled formats
    if [ "$enable_human" = "true" ]; then
        log_human "$timestamp" "$cpu" "$memory" "$disk" "$platform"
    fi

    if [ "$enable_json" = "true" ]; then
        log_json "$timestamp" "$cpu" "$memory" "$disk" "$platform"
    fi

    if [ "$enable_csv" = "true" ]; then
        log_csv "$timestamp" "$cpu" "$memory" "$disk" "$platform"
    fi
}
