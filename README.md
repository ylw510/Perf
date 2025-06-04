# Perf Flamegraph Toolkit for ClickHouse

This repository provides a shell-based toolkit for profiling ClickHouse server performance using Linux `perf`, and generating Flamegraphs for performance analysis.

## Features

- Automatically locates ClickHouse process
- Collects perf sampling data
- Converts to folded stack format
- Generates SVG Flamegraphs
- Archives previous outputs into `./history/`

## Requirements

- `perf`
- `perl`
- `stackcollapse-perf.pl`
- `flamegraph.pl`
- ClickHouse server running

## Usage

```bash
./do_perf.sh [duration]

