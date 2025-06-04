#!/bin/bash

# Function to display usage
show_help() {
  echo "Usage: $0 [duration]"
  echo
  echo "Generates a Flamegraph for ClickHouse server using perf."
  echo
  echo "Arguments:"
  echo "  duration    Sampling duration in seconds (default: 30)"
  echo
  echo "Example:"
  echo "  $0 60"
  echo
  echo "This script will:"
  echo "  - Archive the last run's output directory ./output/ into ./history/YYYYMMDD_HHMMSS/"
  echo "  - Save new output to ./output/"
  echo
  exit 0
}

# Help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
fi

# Default sampling duration
sampling_duration=${1:-30}

timestamp=$(date +"%Y%m%d_%H%M%S")
output_dir="./output"
history_dir="./history"

# Check perf
if ! command -v perf &> /dev/null; then
  echo "Error: 'perf' is not installed."
  echo "Please install perf. Example for Ubuntu:"
  echo "  sudo apt-get install linux-tools-$(uname -r) linux-tools-common"
  exit 1
fi

# Check helper scripts
if [ ! -x ./stackcollapse-perf.pl ] || [ ! -x ./flamegraph.pl ]; then
  echo "Error: stackcollapse-perf.pl or flamegraph.pl not found or not executable."
  echo "Get them from https://github.com/brendangregg/Flamegraph"
  exit 1
fi

# Archive old output directory if not empty
if [ -d "$output_dir" ] && [ "$(ls -A $output_dir)" ]; then
  mkdir -p "$history_dir/$timestamp"
  echo "Archiving old output directory $output_dir to $history_dir/$timestamp/"
  mv "$output_dir"/* "$history_dir/$timestamp/"
fi

# Make sure output directory exists
if [ ! -d "$output_dir" ]; then
  mkdir -p "$output_dir"
  echo "Created output directory: $output_dir"
else
  echo "Using existing output directory: $output_dir"
fi

# Get ClickHouse server PID
clickhouse_server_pid=$(ps ux | grep clickhouse-server | grep -v grep | awk '{print $2}')

if [ -z "$clickhouse_server_pid" ]; then
  echo "ClickHouse server process not found."
  exit 1
fi

echo "ClickHouse Server PID: $clickhouse_server_pid"
echo "Sampling duration: $sampling_duration seconds"
echo "Output directory: $output_dir"

# Run perf record
echo "Running perf record..."
perf record -F 99 -p "$clickhouse_server_pid" -g -- sleep "$sampling_duration"

# Run perf script (may take some time)
echo "Generating perf.unfold... (this may take a while)"
perf script -i perf.data &> "$output_dir/perf.unfold"

# Collapse stack traces
echo "Collapsing stack traces..."
./stackcollapse-perf.pl "$output_dir/perf.unfold" &> "$output_dir/perf.folded"

# Generate flamegraph
echo "Generating flamegraph..."
./flamegraph.pl "$output_dir/perf.folded" > "$output_dir/perf.svg"

# Clean up top-level perf.data
rm -f perf.data

echo "✅ Flamegraph generated: $output_dir/perf.svg"

