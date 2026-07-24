#!/usr/bin/env bash
# unfreeze-b.sh - Verify cluster B is serving traffic on port 30081.
# Task 6 of Project 6.
# Usage: ./scripts/unfreeze-b.sh

set -euo pipefail

STUDENT_ID="${STUDENT_ID:-114441256}"
CONTEXT_B="kind-b"
NAMESPACE="migrate-${STUDENT_ID}"
APP="app-${STUDENT_ID}"
B_URL="http://localhost:30081"

echo "=== UNFREEZE-B: pointing traffic at cluster B (${B_URL}) ==="

echo "Ensuring app-${STUDENT_ID} on cluster B is scaled to 2 replicas..."
kubectl --context "${CONTEXT_B}" -n "${NAMESPACE}" scale deployment "${APP}" --replicas=2

echo "Waiting for cluster B app to serve HTTP 200..."
for i in $(seq 1 30); do
  if curl -sfo /dev/null "${B_URL}"; then
    echo "Cluster B is serving traffic at ${B_URL}"
    break
  fi
  echo "attempt ${i}: cluster B not yet serving, sleeping 2s"
  sleep 2
done

echo "Fetching page from cluster B:"
curl -s "${B_URL}" | grep -E "Cluster:|Student ID:|Row count:|big" | head -5

echo "=== UNFREEZE-B complete ==="
