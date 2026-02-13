#!/bin/bash

# Network Monitoring Library
# Tracks bandwidth, connections, packets, and errors

get_network_stats_linux() {
    local interface=$1
    # Read from /sys/class/net for interface statistics
    if [ -f "/sys/class/net/${interface}/statistics/rx_bytes" ]; then
        local rx_bytes=$(cat /sys/class/net/${interface}/statistics/rx_bytes 2>/dev/null)
        local tx_bytes=$(cat /sys/class/net/${interface}/statistics/tx_bytes 2>/dev/null)
        local rx_packets=$(cat /sys/class/net/${interface}/statistics/rx_packets 2>/dev/null)
        local tx_packets=$(cat /sys/class/net/${interface}/statistics/tx_packets 2>/dev/null)
        local rx_errors=$(cat /sys/class/net/${interface}/statistics/rx_errors 2>/dev/null)
        local tx_errors=$(cat /sys/class/net/${interface}/statistics/tx_errors 2>/dev/null)
        echo "${rx_bytes} ${tx_bytes} ${rx_packets} ${tx_packets} ${rx_errors} ${tx_errors}"
    else
        echo "N/A N/A N/A N/A N/A N/A"
    fi
}

get_network_stats_macos() {
    local interface=$1
    # Use netstat -ib to get interface statistics
    local stats=$(netstat -ib | grep "^${interface}" | head -1 | awk '{print $7, $10, $5, $8, $6, $9}' 2>/dev/null)
    if [ -n "$stats" ]; then
        echo "$stats"
    else
        echo "N/A N/A N/A N/A N/A N/A"
    fi
}

get_network_stats() {
    local interface=$1
    local platform=$2
    if [ "$platform" = "linux" ]; then
        get_network_stats_linux "$interface"
    elif [ "$platform" = "macOS" ]; then
        get_network_stats_macos "$interface"
    fi
}

get_connection_count_linux() {
    if command -v ss >/dev/null 2>&1; then
        local tcp=$(ss -t 2>/dev/null | tail -n +2 | wc -l)
        local udp=$(ss -u 2>/dev/null | tail -n +2 | wc -l)
        local established=$(ss -t state established 2>/dev/null | tail -n +2 | wc -l)
        echo "$tcp $udp $established"
    else
        echo "N/A N/A N/A"
    fi
}

get_connection_count_macos() {
    local tcp=$(netstat -an 2>/dev/null | grep -c "tcp.*ESTABLISHED")
    local udp=$(netstat -an 2>/dev/null | grep -c "udp")
    echo "$tcp $udp $tcp"
}

get_connection_count() {
    local platform=$1
    if [ "$platform" = "linux" ]; then
        get_connection_count_linux
    elif [ "$platform" = "macOS" ]; then
        get_connection_count_macos
    fi
}

format_network_summary() {
    local interface=$1
    local stats=$2
    local connections=$3

    local rx_bytes=$(echo "$stats" | awk '{print $1}')
    local tx_bytes=$(echo "$stats" | awk '{print $2}')
    local rx_packets=$(echo "$stats" | awk '{print $3}')
    local tx_packets=$(echo "$stats" | awk '{print $4}')
    local rx_errors=$(echo "$stats" | awk '{print $5}')
    local tx_errors=$(echo "$stats" | awk '{print $6}')

    local tcp=$(echo "$connections" | awk '{print $1}')
    local udp=$(echo "$connections" | awk '{print $2}')
    local established=$(echo "$connections" | awk '{print $3}')

    # Convert bytes to MB for display
    if [ "$rx_bytes" != "N/A" ] && [ -n "$rx_bytes" ]; then
        local rx_mb=$(awk "BEGIN {printf \"%.2f\", $rx_bytes/1048576}")
        local tx_mb=$(awk "BEGIN {printf \"%.2f\", $tx_bytes/1048576}")
        echo "RX:${rx_mb}MB TX:${tx_mb}MB PKT:${rx_packets}/${tx_packets} ERR:${rx_errors}/${tx_errors} CONN:${tcp}/${udp}/${established}"
    else
        echo "N/A"
    fi
}
