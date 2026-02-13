#!/bin/bash

# Service Health Check Library
# Monitors systemd/launchd services and processes

check_systemd_service_linux() {
    local service=$1
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active "$service" >/dev/null 2>&1; then
            local uptime=$(systemctl show "$service" -p ActiveEnterTimestamp --value 2>/dev/null | cut -d' ' -f2-3 2>/dev/null || echo "unknown")
            echo "active|$uptime"
        else
            local status=$(systemctl is-active "$service" 2>/dev/null || echo "unknown")
            echo "${status}|N/A"
        fi
    else
        echo "not-found|systemctl not available"
    fi
}

check_launchd_service_macos() {
    local service=$1
    if command -v launchctl >/dev/null 2>&1; then
        local info=$(launchctl list | grep "$service" 2>/dev/null)
        if [ -n "$info" ]; then
            local pid=$(echo "$info" | awk '{print $1}')
            if [ "$pid" != "-" ] && [ -n "$pid" ] && [ "$pid" != "0" ]; then
                local uptime=$(ps -p "$pid" -o etime= 2>/dev/null | xargs)
                echo "running|${uptime:-N/A}"
            else
                echo "stopped|N/A"
            fi
        else
            echo "not-found|N/A"
        fi
    else
        echo "not-found|launchctl not available"
    fi
}

check_service_status() {
    local service=$1
    local platform=$2
    if [ "$platform" = "linux" ]; then
        check_systemd_service_linux "$service"
    elif [ "$platform" = "macOS" ]; then
        check_launchd_service_macos "$service"
    fi
}

check_process_running() {
    local process=$1
    if command -v pgrep >/dev/null 2>&1; then
        if pgrep -x "$process" >/dev/null 2>&1; then
            local pid=$(pgrep -x "$process" | head -1)
            local uptime=$(ps -p "$pid" -o etime= 2>/dev/null | xargs)
            local count=$(pgrep -x "$process" | wc -l | xargs)
            echo "running|${pid}|${uptime:-N/A}|${count}"
        else
            echo "stopped|N/A|N/A|0"
        fi
    else
        echo "unknown|pgrep not available|N/A|0"
    fi
}

format_service_status() {
    local service=$1
    local status=$2

    local state=$(echo "$status" | cut -d'|' -f1)
    local uptime=$(echo "$status" | cut -d'|' -f2)

    local symbol="✗"
    if [ "$state" = "active" ] || [ "$state" = "running" ]; then
        symbol="✓"
    fi

    if [ "$uptime" != "N/A" ] && [ -n "$uptime" ]; then
        echo "    [$symbol] ${service} (${state}, uptime: ${uptime})"
    else
        echo "    [$symbol] ${service} (${state})"
    fi
}

format_process_status() {
    local process=$1
    local status=$2

    local state=$(echo "$status" | cut -d'|' -f1)
    local pid=$(echo "$status" | cut -d'|' -f2)
    local uptime=$(echo "$status" | cut -d'|' -f3)
    local count=$(echo "$status" | cut -d'|' -f4)

    if [ "$state" = "running" ]; then
        echo "    Process ${process}: running (${count} instances, PID: ${pid}, uptime: ${uptime})"
    else
        echo "    Process ${process}: ${state}"
    fi
}
