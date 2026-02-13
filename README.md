# Linux/macOS System Monitor

A lightweight, configurable system monitoring tool for Linux and macOS that tracks CPU, memory, disk usage, and resource intensive processes with multi-format logging.

## Features

- **Cross-platform**: Works on both Linux and macOS
- **Configurable monitoring**: JSON-based configuration for thresholds, intervals, and metrics
- **Process tracking**: Monitors top N resource-consuming processes
- **Multi-format logging**: Outputs to human readable, JSON, and CSV formats

## Quick Start

### Prerequisites

- Bash shell
- `jq` (JSON processor)
  - macOS: `brew install jq`
  - Linux: `apt install jq` or `yum install jq`

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
      "processes": true
    },
    "process_monitoring": {
      "enabled": true,
      "top_count": 5
    }
  },
  "thresholds": {
    "cpu_percent": 80,
    "memory_percent": 80,
    "disk_percent": 80
  },
  "logging": {
    "enabled": true,
    "formats": {
      "human_readable": true,
      "json": true,
      "csv": true
    }
  }
}
```

### Key Settings

- `interval_seconds`: Monitoring frequency (default: 5)
- `metrics_enabled`: Toggle individual metrics on/off
- `top_count`: Number of top processes to track (default: 5)
- `thresholds`: Alert levels for each metric (0-100)
- `formats`: Enable/disable specific log formats

## Output Formats

Logs are stored in `logs/<platform>/`
