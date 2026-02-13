#!/bin/bash

# Advanced System Metrics Library
# Load averages, swap, disk I/O, temperature

get_load_average_linux() {
    if [ -f /proc/loadavg ]; then
        local load=$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}')
        if [ -n "$load" ]; then
            echo "$load"
            return
        fi
    fi
    # Fallback to uptime
    uptime | awk -F'load average:' '{print $2}' | sed 's/,//g' | xargs
}

get_load_average_macos() {
    uptime | awk -F'load averages:' '{print $2}' | sed 's/,//g' | xargs
}

get_load_average() {
    local platform=$1
    if [ "$platform" = "linux" ]; then
        get_load_average_linux
    elif [ "$platform" = "macOS" ]; then
        get_load_average_macos
    fi
}

get_swap_usage_linux() {
    if command -v free >/dev/null 2>&1; then
        local swap_info=$(free -m 2>/dev/null | grep Swap)
        if [ -n "$swap_info" ]; then
            local total=$(echo "$swap_info" | awk '{print $2}')
            local used=$(echo "$swap_info" | awk '{print $3}')
            if [ "$total" -gt 0 ] 2>/dev/null; then
                local percent=$(awk "BEGIN {printf \"%.1f\", ($used/$total)*100}")
                echo "$total $used $percent"
                return
            fi
        fi
    fi
    echo "0 0 0"
}

get_swap_usage_macos() {
    if command -v sysctl >/dev/null 2>&1; then
        local swap_info=$(sysctl vm.swapusage 2>/dev/null | awk '{print $3, $6}' | sed 's/M//g')
        if [ -n "$swap_info" ]; then
            local total=$(echo "$swap_info" | awk '{print $1}')
            local used=$(echo "$swap_info" | awk '{print $2}')
            # Remove any non-numeric characters
            total=$(echo "$total" | sed 's/[^0-9.]//g')
            used=$(echo "$used" | sed 's/[^0-9.]//g')
            if [ -n "$total" ] && [ -n "$used" ] && [ "$total" != "0" ]; then
                local percent=$(awk "BEGIN {printf \"%.1f\", ($used/$total)*100}")
                echo "$total $used $percent"
                return
            fi
        fi
    fi
    echo "0 0 0"
}

get_swap_stats() {
    local platform=$1
    if [ "$platform" = "linux" ]; then
        get_swap_usage_linux
    elif [ "$platform" = "macOS" ]; then
        get_swap_usage_macos
    fi
}

get_disk_io_linux() {
    if command -v iostat >/dev/null 2>&1; then
        local io_stats=$(iostat -d -x 1 2 2>/dev/null | tail -n 1 | awk '{print $4, $5, $14}')
        if [ -n "$io_stats" ]; then
            echo "$io_stats"
            return
        fi
    fi
    echo "N/A N/A N/A"
}

get_disk_io_macos() {
    if command -v iostat >/dev/null 2>&1; then
        local io_stats=$(iostat -d -c 2 -w 1 2>/dev/null | tail -n 1 | awk '{print $1, $2, 0}')
        if [ -n "$io_stats" ]; then
            echo "$io_stats"
            return
        fi
    fi
    echo "N/A N/A N/A"
}

get_disk_io_stats() {
    local platform=$1
    if [ "$platform" = "linux" ]; then
        get_disk_io_linux
    elif [ "$platform" = "macOS" ]; then
        get_disk_io_macos
    fi
}

get_temperature_linux() {
    # Try sensors command first
    if command -v sensors >/dev/null 2>&1; then
        local temp=$(sensors 2>/dev/null | grep -i "core 0" | awk '{print $3}' | sed 's/+//;s/°C//' | head -1)
        if [ -n "$temp" ]; then
            echo "$temp"
            return
        fi
    fi

    # Fallback to /sys/class/thermal
    if [ -d /sys/class/thermal ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        if [ -n "$temp" ]; then
            echo "$((temp / 1000))"
            return
        fi
    fi

    echo "N/A"
}

get_temperature_macos() {
    # Try osx-cpu-temp command
    if command -v osx-cpu-temp >/dev/null 2>&1; then
        local temp=$(osx-cpu-temp 2>/dev/null | awk '{print $1}' | sed 's/°C//')
        if [ -n "$temp" ]; then
            echo "$temp"
            return
        fi
    fi

    echo "N/A"
}

get_temperature_stats() {
    local platform=$1
    if [ "$platform" = "linux" ]; then
        get_temperature_linux
    elif [ "$platform" = "macOS" ]; then
        get_temperature_macos
    fi
}

format_load_average() {
    local load=$1
    local load_1m=$(echo "$load" | awk '{print $1}')
    local load_5m=$(echo "$load" | awk '{print $2}')
    local load_15m=$(echo "$load" | awk '{print $3}')
    echo "1m:${load_1m} 5m:${load_5m} 15m:${load_15m}"
}

format_swap_stats() {
    local swap=$1
    local total=$(echo "$swap" | awk '{print $1}')
    local used=$(echo "$swap" | awk '{print $2}')
    local percent=$(echo "$swap" | awk '{print $3}')

    if [ "$total" = "0" ]; then
        echo "No swap configured"
    else
        echo "${used}MB / ${total}MB (${percent}%)"
    fi
}

format_disk_io() {
    local io=$1
    local read=$(echo "$io" | awk '{print $1}')
    local write=$(echo "$io" | awk '{print $2}')
    local util=$(echo "$io" | awk '{print $3}')

    if [ "$read" = "N/A" ]; then
        echo "N/A (install iostat)"
    else
        echo "R:${read} W:${write} Util:${util}%"
    fi
}
