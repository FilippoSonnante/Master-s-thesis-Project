#!/bin/bash
set -euo pipefail

# CONFIG
AMF_PID=$(pgrep -f open5gs-amfd | head -n1)
NF_DIR="/home/filippo/NetworkFuzzer"
PCAP="/home/filippo/pcap/5g-sa.pcap"
OUTCSV="${NF_DIR}/amf_cpu_log.csv" #change the nave of the output file every time
DELAY=2                # s between samples
MAX_SAMPLE_SECS=900    # max time (safety)
# packets sent for each try
COPIES_LIST=(10 100 500 1000 5000 8000)

# header CSV
echo "copies,timestamp,elapsed_s,pid,cpu_percent,mem_percent" > "$OUTCSV"

cd "$NF_DIR"

for copies in "${COPIES_LIST[@]}"; do
  echo "==== Starting  test: copies=$copies ===="
  # start NetworkFuzzer in background
  sudo ./networkfuzzer replay -t "$PCAP" -Xforward.nb-copies="$copies" &
  NF_PID=$!
  echo "NetworkFuzzer PID = $NF_PID"

  # sampling loop
  start_ts=$(date +%s)
  elapsed=0
  sample_idx=0
  while kill -0 "$NF_PID" 2>/dev/null && [ $elapsed -lt $MAX_SAMPLE_SECS ]; do
    ts_iso=$(date --iso-8601=seconds)
    # read of CPU and MEMORY of AMF process
    read cpu mem < <(ps -p "$AMF_PID" -o %cpu= -o %mem= 2>/dev/null || echo "0 0")
    sample_idx=$((sample_idx+1))
    echo "${copies},${ts_iso},${sample_idx},${AMF_PID},${cpu},${mem}" >> "$OUTCSV"
    sleep "$DELAY"
    now_ts=$(date +%s)
    elapsed=$((now_ts - start_ts))
  done

echo "All tests completed. Output CSV: $OUTCSV"
