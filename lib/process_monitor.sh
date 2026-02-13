#!/bin/bash

# Process Monitoring Library
# Captures top resource-consuming processes

get_top_processes_macos() {
    local count=${1:-5}
    # Get top processes sorted by CPU, skip header
    ps -A -o pid,%cpu,%mem,comm | sort -rn -k2 | head -n $((count + 1)) | tail -n $count
}

get_top_processes_linux() {
    local count=${1:-5}
    # Get top processes sorted by CPU, skip header
    ps aux --sort=-%cpu | awk 'NR>1 {print $2, $3, $4, $11}' | head -n $count
}

get_top_processes() {
    local count=${1:-5}
    local platform=${2:-"unknown"}

    if [ "$platform" = "macOS" ]; then
        get_top_processes_macos "$count"
    elif [ "$platform" = "linux" ]; then
        get_top_processes_linux "$count"
    else
        echo ""
    fi
}

format_processes_human() {
    local processes="$1"

    if [ -z "$processes" ]; then
        echo "No process data"
        return
    fi

    echo "  Top Processes:"
    echo "$processes" | while IFS= read -r line; do
        echo "    $line"
    done
}

format_processes_json() {
    local processes="$1"

    if [ -z "$processes" ]; then
        echo "[]"
        return
    fi

    local json="["
    local first=true

    echo "$processes" | while IFS= read -r line; do
        local pid=$(echo "$line" | awk '{print $1}')
        local cpu=$(echo "$line" | awk '{print $2}')
        local mem=$(echo "$line" | awk '{print $3}')
        local cmd=$(echo "$line" | awk '{print $4}')

        if [ "$first" = true ]; then
            first=false
        else
            json="${json},"
        fi

        json="${json}{\"pid\":${pid},\"cpu\":${cpu},\"mem\":${mem},\"command\":\"${cmd}\"}"
    done

    echo "${json}]"
}

format_processes_csv() {
    local processes="$1"

    if [ -z "$processes" ]; then
        echo ""
        return
    fi

    echo "$processes" | while IFS= read -r line; do
        local pid=$(echo "$line" | awk '{print $1}')
        local cpu=$(echo "$line" | awk '{print $2}')
        local mem=$(echo "$line" | awk '{print $3}')
        local cmd=$(echo "$line" | awk '{print $4}')
        echo "\"${pid}|${cpu}%|${mem}%|${cmd}\""
    done | paste -sd ";" -
}
