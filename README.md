# Linux/macOS System Monitor

A lightweight, configurable system monitoring tool for Linux and macOS that tracks CPU, memory, disk usage, and resource intensive processes with multi-format logging.

## Features

- **Cross-platform**: Works on both Linux and macOS
- **Configurable monitoring**: JSON-based configuration for thresholds, intervals, and metrics
- **Process tracking**: Monitors top N resource-consuming processes
- **Network monitoring**: Track interface statistics, bandwidth, and connections
- **Service health checks**: Monitor systemd/launchd services and running processes
- **Advanced metrics**: Load averages, swap usage, disk I/O, and CPU temperature
- **Multi-format logging**: Outputs to human readable, JSON, and CSV formats

## Quick Start

### Prerequisites

**Required:**
- Bash shell
- `jq` (JSON processor)
  - macOS: `brew install jq`
  - Linux: `apt install jq` or `yum install jq`

**Optional (for enhanced features):**
- `iostat` - for disk I/O monitoring (sysstat package)
- `sensors` - for temperature monitoring (lm-sensors on Linux)
- `osx-cpu-temp` - for temperature monitoring on macOS

### Installation

```bash
git clone <repository-url>
cd linux-system-monitor
chmod +x system_monitor_*.sh
```

### Running

**On macOS:**

```bash
./system_monitor_macOS.sh
```

**On Linux:**

```bash
./system_monitor_linux.sh
```

Stop monitoring with `Ctrl+C`.

## Configuration

Edit `config.json` to customise behavior:

```json
{
  "monitoring": {
    "interval_seconds": 5,
    "metrics_enabled": {
      "cpu": true,
      "memory": true,
      "disk": true,
      "processes": true,
      "network": true,
      "services": true,
      "advanced_metrics": true
    },
    "network_monitoring": {
      "enabled": true,
      "interfaces": ["eth0", "wlan0"],
      "track_bandwidth": true,
      "track_connections": true
    },
    "service_monitoring": {
      "enabled": true,
      "services": ["ssh", "cron", "docker"],
      "processes_to_monitor": ["nginx", "postgres"]
    },
    "advanced_metrics": {
      "enabled": true,
      "load_average": true,
      "swap_usage": true,
      "disk_io": true,
      "temperature": true
    }
  },
  "thresholds": {
    "cpu_percent": 80,
    "memory_percent": 80,
    "disk_percent": 80,
    "load_average_1m": 2.0,
    "swap_percent": 50,
    "temperature_celsius": 80
  }
}
```

### Key Settings

- `interval_seconds`: Monitoring frequency (default: 5)
- `metrics_enabled`: Toggle individual metrics on/off
- `top_count`: Number of top processes to track (default: 5)
- `interfaces`: Network interfaces to monitor (e.g., ["en0"] for macOS, ["eth0"] for Linux)
- `services`: System services to monitor (systemd on Linux, launchd on macOS)
- `processes_to_monitor`: Specific processes to track
- `thresholds`: Alert levels for each metric
- `formats`: Enable/disable specific log formats

## Output Formats

Logs are stored in `logs/<platform>/`
