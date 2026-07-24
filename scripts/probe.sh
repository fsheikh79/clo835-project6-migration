#!/usr/bin/env bash
# probe.sh - Probe a URL once per second, log timestamped result.
# Task 8 of Project 6.
# Usage: ./scripts/probe.sh http://localhost:30080
# Log: evidence/probe.log
# Stop with Ctrl+C.

set -u

if [ $# -lt 1 ]; then
  echo "Usage: $0 <url>   (e.g., $0 http://localhost:30080)"
  exit 1
fi

URL="$1"
LOG="evidence/probe.log"

mkdir -p evidence
touch "${LOG}"

echo "=== PROBE: hitting ${URL} once per second ==="
echo "Log file: ${LOG}"
echo "Press Ctrl+C to stop."
echo ""

echo "--- probe started $(date -u +"%Y-%m-%dT%H:%M:%SZ") for ${URL} ---" | tee -a "${LOG}"

while true; do
  TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" --max-time 2 "${URL}" || echo "000")
  if [ "${HTTP_CODE}" = "200" ]; then
    STATUS="SUCCESS"
  else
    STATUS="FAILURE"
  fi
  LINE="${TS} ${STATUS} http=${HTTP_CODE} url=${URL}"
  echo "${LINE}" | tee -a "${LOG}"
  sleep 1
done
