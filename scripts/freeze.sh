#!/usr/bin/env bash
# freeze.sh - Stop writes on cluster A by scaling the app to 0 replicas.
# Task 6 of Project 6.
# Usage: ./scripts/freeze.sh

set -euo pipefail

STUDENT_ID="${STUDENT_ID:-114441256}"
CONTEXT="${CONTEXT:-kind-a}"
NAMESPACE="migrate-${STUDENT_ID}"
APP="app-${STUDENT_ID}"

echo "=== FREEZE: scaling ${APP} to 0 replicas on ${CONTEXT} ==="
kubectl --context "${CONTEXT}" -n "${NAMESPACE}" scale deployment "${APP}" --replicas=0

echo "Waiting for rollout to complete (all pods terminated)..."
kubectl --context "${CONTEXT}" -n "${NAMESPACE}" rollout status deployment "${APP}" --timeout=60s

echo ""
echo "Current deployment state on ${CONTEXT}:"
kubectl --context "${CONTEXT}" -n "${NAMESPACE}" get deployment "${APP}"

echo ""
echo "Pods for ${APP} on ${CONTEXT}:"
POD_COUNT=$(kubectl --context "${CONTEXT}" -n "${NAMESPACE}" get pods -l app="${APP}" --no-headers 2>/dev/null | wc -l)
if [ "${POD_COUNT}" -eq 0 ]; then
  echo "(no pods — writes are frozen)"
else
  kubectl --context "${CONTEXT}" -n "${NAMESPACE}" get pods -l app="${APP}"
fi

echo ""
echo "=== FREEZE complete ==="
