#!/bin/bash

# Configuration Parser Library
# Provides functions to read and validate JSON configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.json"

get_config_value() {
    local json_path=$1
    local default_value=${2:-""}

    if [ -f "$CONFIG_FILE" ]; then
        local value=$(jq -r "$json_path" "$CONFIG_FILE" 2>/dev/null)
        if [ $? -eq 0 ] && [ "$value" != "null" ] && [ -n "$value" ]; then
            echo "$value"
        else
            echo "$default_value"
        fi
    else
        echo "$default_value"
    fi
}

load_config() {
    # Thresholds
    export CPU_THRESHOLD=$(get_config_value ".thresholds.cpu_percent" "80")
    export MEMORY_THRESHOLD=$(get_config_value ".thresholds.memory_percent" "80")
    export DISK_THRESHOLD=$(get_config_value ".thresholds.disk_percent" "80")

    # Monitoring settings
    export MONITORING_INTERVAL=$(get_config_value ".monitoring.interval_seconds" "5")
    export ENABLE_CPU=$(get_config_value ".monitoring.metrics_enabled.cpu" "true")
    export ENABLE_MEMORY=$(get_config_value ".monitoring.metrics_enabled.memory" "true")
    export ENABLE_DISK=$(get_config_value ".monitoring.metrics_enabled.disk" "true")

    # Display settings
    export COLORS_ENABLED=$(get_config_value ".display.colors_enabled" "true")
    export SHOW_TIMESTAMP=$(get_config_value ".display.show_timestamp" "true")

    # Logging settings
    export LOG_DIR=$(get_config_value ".logging.log_directory" "logs")
    export LOGGING_ENABLED=$(get_config_value ".logging.enabled" "true")
}

validate_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "⚠️  Warning: Config file not found at $CONFIG_FILE"
        echo "   Using default values..."
        return 1
    fi

    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo "❌ Error: Config file is not valid JSON"
        echo "   Check $CONFIG_FILE for syntax errors"
        return 1
    fi

    echo "✅ Configuration loaded from $CONFIG_FILE"
    return 0
}

print_config() {
    echo "Current Configuration:"
    echo "  Thresholds: CPU=${CPU_THRESHOLD}% MEM=${MEMORY_THRESHOLD}% DISK=${DISK_THRESHOLD}%"
    echo "  Interval: ${MONITORING_INTERVAL}s"
    echo "  Enabled: CPU=${ENABLE_CPU} Memory=${ENABLE_MEMORY} Disk=${ENABLE_DISK}"
    echo "  Log Directory: ${LOG_DIR}"
}
