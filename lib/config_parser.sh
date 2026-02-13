#!/bin/bash

# =============================================================================
# Configuration Parser Library
# =============================================================================
# This library provides functions to read and validate configuration from JSON.
# It demonstrates several important programming concepts:
#
# 1. SEPARATION OF CONCERNS: Config logic is isolated from business logic
# 2. REUSABILITY: Can be sourced by any script that needs config
# 3. ERROR HANDLING: Gracefully handles missing files/values
# 4. DEFAULT VALUES: Provides fallbacks if config is incomplete
# =============================================================================

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
# The directory where this script lives (used to find config.json)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.json"

# -----------------------------------------------------------------------------
# Function: get_config_value
# -----------------------------------------------------------------------------
# Reads a value from the JSON config file using jq (JSON query tool)
#
# PARAMETERS:
#   $1 - JSON path (e.g., ".thresholds.cpu_percent")
#   $2 - Default value if not found (optional)
#
# RETURNS:
#   The config value or default value
# -----------------------------------------------------------------------------
get_config_value() {
    local json_path=$1
    local default_value=${2:-""}

    # Try to read from config file
    if [ -f "$CONFIG_FILE" ]; then
        # jq reads JSON and extracts the value at json_path
        # Example: jq -r '.thresholds.cpu_percent' config.json
        # Returns: 80
        local value=$(jq -r "$json_path" "$CONFIG_FILE" 2>/dev/null)

        # Check if jq succeeded and returned a valid value
        if [ $? -eq 0 ] && [ "$value" != "null" ] && [ -n "$value" ]; then
            echo "$value"
        else
            echo "$default_value"
        fi
    else
        echo "$default_value"
    fi
}

# -----------------------------------------------------------------------------
# Function: load_config
# -----------------------------------------------------------------------------
# Loads all configuration values into global variables
# This is called once at script startup
#
# -----------------------------------------------------------------------------
load_config() {
    # -----------------------------------------------------------------
    # THRESHOLDS
    # -----------------------------------------------------------------
    # Using export makes these variables available to all functions
    export CPU_THRESHOLD=$(get_config_value ".thresholds.cpu_percent" "80")
    export MEMORY_THRESHOLD=$(get_config_value ".thresholds.memory_percent" "80")
    export DISK_THRESHOLD=$(get_config_value ".thresholds.disk_percent" "80")

    # -----------------------------------------------------------------
    # MONITORING SETTINGS
    # -----------------------------------------------------------------
    export MONITORING_INTERVAL=$(get_config_value ".monitoring.interval_seconds" "5")
    export ENABLE_CPU=$(get_config_value ".monitoring.metrics_enabled.cpu" "true")
    export ENABLE_MEMORY=$(get_config_value ".monitoring.metrics_enabled.memory" "true")
    export ENABLE_DISK=$(get_config_value ".monitoring.metrics_enabled.disk" "true")

    # -----------------------------------------------------------------
    # DISPLAY SETTINGS
    # -----------------------------------------------------------------
    export COLORS_ENABLED=$(get_config_value ".display.colors_enabled" "true")
    export SHOW_TIMESTAMP=$(get_config_value ".display.show_timestamp" "true")

    # -----------------------------------------------------------------
    # LOGGING SETTINGS
    # -----------------------------------------------------------------
    export LOG_DIR=$(get_config_value ".logging.log_directory" "logs")
    export LOGGING_ENABLED=$(get_config_value ".logging.enabled" "true")
}

# -----------------------------------------------------------------------------
# Function: validate_config
# -----------------------------------------------------------------------------
# Checks if the config file exists and is valid JSON
#
# RETURNS:
#   0 if valid, 1 if invalid
#
# -----------------------------------------------------------------------------
validate_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Warning: Config file not found at $CONFIG_FILE"
        echo "   Using default values..."
        return 1
    fi

    # Test if the file is valid JSON by trying to parse it
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo "Error: Config file is not valid JSON"
        echo "Check $CONFIG_FILE for syntax errors"
        return 1
    fi

    echo "Configuration loaded from $CONFIG_FILE"
    return 0
}

# -----------------------------------------------------------------------------
# Function: print_config
# -----------------------------------------------------------------------------
# Prints the current configuration (useful for debugging)
#
# LEARNING POINTS:
#   - Debugging helpers make development easier
#   - Clear output helps users understand what's happening
# -----------------------------------------------------------------------------
print_config() {
    echo "Current Configuration:"
    echo "  Thresholds: CPU=${CPU_THRESHOLD}% MEM=${MEMORY_THRESHOLD}% DISK=${DISK_THRESHOLD}%"
    echo "  Interval: ${MONITORING_INTERVAL}s"
    echo "  Enabled: CPU=${ENABLE_CPU} Memory=${ENABLE_MEMORY} Disk=${ENABLE_DISK}"
    echo "  Log Directory: ${LOG_DIR}"
}

# -----------------------------------------------------------------------------
# USAGE EXAMPLE:
# -----------------------------------------------------------------------------
# In your main script, do this:
#
#   source lib/config_parser.sh  # Load this library
#   validate_config              # Check if config is valid
#   load_config                  # Load all values
#   print_config                 # Show what was loaded
#
# Then use the variables:
#   if [ "$ENABLE_CPU" = "true" ]; then
#       # Monitor CPU
#   fi
# -----------------------------------------------------------------------------