#!/bin/bash

# Configuration Parser Library
# Provides functions to read and validate JSON configuration

_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${_LIB_DIR}/../config.json"

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
    export LOAD_THRESHOLD_1M=$(get_config_value ".thresholds.load_average_1m" "2.0")
    export LOAD_THRESHOLD_5M=$(get_config_value ".thresholds.load_average_5m" "1.5")
    export LOAD_THRESHOLD_15M=$(get_config_value ".thresholds.load_average_15m" "1.0")
    export SWAP_THRESHOLD=$(get_config_value ".thresholds.swap_percent" "50")
    export DISK_IO_THRESHOLD=$(get_config_value ".thresholds.disk_io_util" "80")
    export TEMP_THRESHOLD=$(get_config_value ".thresholds.temperature_celsius" "80")
    export NETWORK_ERROR_THRESHOLD=$(get_config_value ".thresholds.network_errors_per_sec" "10")

    # Monitoring settings
    export MONITORING_INTERVAL=$(get_config_value ".monitoring.interval_seconds" "5")
    export ENABLE_CPU=$(get_config_value ".monitoring.metrics_enabled.cpu" "true")
    export ENABLE_MEMORY=$(get_config_value ".monitoring.metrics_enabled.memory" "true")
    export ENABLE_DISK=$(get_config_value ".monitoring.metrics_enabled.disk" "true")
    export ENABLE_PROCESSES=$(get_config_value ".monitoring.process_monitoring.enabled" "false")
    export PROCESS_TOP_COUNT=$(get_config_value ".monitoring.process_monitoring.top_count" "5")

    # Network monitoring
    export ENABLE_NETWORK=$(get_config_value ".monitoring.metrics_enabled.network" "false")
    export NETWORK_INTERFACES=$(get_config_value ".monitoring.network_monitoring.interfaces | join(\",\")" "en0")
    export NETWORK_TRACK_BANDWIDTH=$(get_config_value ".monitoring.network_monitoring.track_bandwidth" "true")
    export NETWORK_TRACK_CONNECTIONS=$(get_config_value ".monitoring.network_monitoring.track_connections" "true")

    # Service monitoring
    export ENABLE_SERVICES=$(get_config_value ".monitoring.metrics_enabled.services" "false")
    export SERVICES_TO_MONITOR=$(get_config_value ".monitoring.service_monitoring.services | join(\",\")" "")
    export PROCESSES_TO_MONITOR=$(get_config_value ".monitoring.service_monitoring.processes_to_monitor | join(\",\")" "")

    # Advanced metrics
    export ENABLE_ADVANCED=$(get_config_value ".monitoring.metrics_enabled.advanced_metrics" "false")
    export TRACK_LOAD_AVERAGE=$(get_config_value ".monitoring.advanced_metrics.load_average" "true")
    export TRACK_SWAP=$(get_config_value ".monitoring.advanced_metrics.swap_usage" "true")
    export TRACK_DISK_IO=$(get_config_value ".monitoring.advanced_metrics.disk_io" "true")
    export TRACK_TEMPERATURE=$(get_config_value ".monitoring.advanced_metrics.temperature" "true")

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
    echo "  Network=${ENABLE_NETWORK} Services=${ENABLE_SERVICES} Advanced=${ENABLE_ADVANCED}"
    echo "  Log Directory: ${LOG_DIR}"
}
