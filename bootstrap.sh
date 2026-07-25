#!/usr/bin/env bash
# bootstrap.sh - Bring cluster A (and optionally cluster B) up from a clean host.
# Task 10 of Project 6. Must complete in under 15 minutes.
#
# Usage: ./bootstrap.sh              # cluster A only
#        ./bootstrap.sh --with-b     # both clusters

set -euo pipefail

# ---- Configuration (Task 11: single source of truth) ----
STUDENT_ID="${STUDENT_ID:-114441256}"
NAMESPACE="migrate-${STUDENT_ID}"
HOST_MIGRATE_DIR="/tmp/migrate-${STUDENT_ID}"
CLUSTER_A="a"
CLUSTER_B="b"
CONTEXT_A="kind-${CLUSTER_A}"
CONTEXT_B="kind-${CLUSTER_B}"
KIND_CONFIG_A="kind/cluster-a.yaml"
KIND_CONFIG_B="kind/cluster-b.yaml"
WITH_B=false

if [ "${1:-}" = "--with-b" ]; then
  WITH_B=true
fi

START_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "============================================================"
echo "CLO835 Project 6 - bootstrap.sh"
echo "Student ID:      ${STUDENT_ID}"
echo "Namespace:       ${NAMESPACE}"
echo "Host dir:        ${HOST_MIGRATE_DIR}"
echo "Cluster A ctx:   ${CONTEXT_A}"
echo "With cluster B?  ${WITH_B}"
echo "Started:         ${START_TS}"
echo "============================================================"

# ---- Preflight checks ----
echo ""
echo "[1/8] Preflight: checking required tools..."
for tool in docker kind kubectl sha256sum curl; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "ERROR: ${tool} is not installed"
    exit 1
  fi
done
echo "  All tools present"

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: docker daemon is not running (try: sudo service docker start)"
  exit 1
fi
echo "  Docker daemon is running"

# ---- Prepare host directory for hostPath transport ----
echo ""
echo "[2/8] Preparing host directory ${HOST_MIGRATE_DIR}..."
mkdir -p "${HOST_MIGRATE_DIR}"
rm -f "${HOST_MIGRATE_DIR}/dump.sql"
echo "  Ready"

# ---- Tear down any existing cluster A for a clean start ----
echo ""
echo "[3/8] Removing any existing cluster ${CLUSTER_A}..."
kind delete cluster --name "${CLUSTER_A}" 2>/dev/null || true

# ---- Create cluster A ----
echo ""
echo "[4/8] Creating cluster ${CLUSTER_A} from ${KIND_CONFIG_A}..."
kind create cluster --config "${KIND_CONFIG_A}"

# ---- Apply cluster A manifests in order ----
echo ""
echo "[5/8] Applying manifests to ${CONTEXT_A}..."
for f in manifests/a/00-namespace.yaml \
         manifests/a/01-secret.yaml \
         manifests/a/02-configmap.yaml \
         manifests/a/03-db-pvc.yaml \
         manifests/a/04-db-deployment.yaml \
         manifests/a/05-db-service.yaml \
         manifests/a/06-app-deployment.yaml \
         manifests/a/07-app-service.yaml; do
  echo "  applying ${f}"
  kubectl --context "${CONTEXT_A}" apply -f "${f}"
done

# ---- Wait for DB to be ready ----
echo ""
echo "[6/8] Waiting for DB deployment to become ready on ${CONTEXT_A}..."
kubectl --context "${CONTEXT_A}" -n "${NAMESPACE}" rollout status deployment "db-${STUDENT_ID}" --timeout=300s

echo "  Waiting for seed (500 rows) to be visible..."
for i in $(seq 1 30); do
  COUNT=$(kubectl --context "${CONTEXT_A}" -n "${NAMESPACE}" exec deploy/"db-${STUDENT_ID}" -- \
    bash -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -N -B -e "SELECT COUNT(*) FROM appdb.records;" 2>/dev/null' 2>/dev/null || echo "0")
  if [ "${COUNT}" -ge 500 ]; then
    echo "  Seed complete: ${COUNT} rows"
    break
  fi
  echo "    attempt ${i}: count=${COUNT}, waiting..."
  sleep 2
done

# ---- Wait for app to be ready ----
echo ""
echo "[7/8] Waiting for app deployment on ${CONTEXT_A}..."
kubectl --context "${CONTEXT_A}" -n "${NAMESPACE}" rollout status deployment "app-${STUDENT_ID}" --timeout=180s
echo "  Waiting for app URL to serve HTTP 200..."
for i in $(seq 1 30); do
  if curl -sfo /dev/null http://localhost:30080; then
    echo "  App serving at http://localhost:30080"
    break
  fi
  echo "    attempt ${i}: not yet, waiting..."
  sleep 2
done

# ---- Optionally create cluster B ----
if [ "${WITH_B}" = "true" ]; then
  echo ""
  echo "[8/8] Creating cluster ${CLUSTER_B}..."
  kind delete cluster --name "${CLUSTER_B}" 2>/dev/null || true
  kind create cluster --config "${KIND_CONFIG_B}"

  echo "  Applying manifests to ${CONTEXT_B}..."
  for f in manifests/b/00-namespace.yaml \
           manifests/b/01-secret.yaml \
           manifests/b/02-configmap.yaml \
           manifests/b/03-db-pvc.yaml \
           manifests/b/04-db-deployment.yaml \
           manifests/b/05-db-service.yaml \
           manifests/b/06-app-deployment.yaml \
           manifests/b/07-app-service.yaml; do
    echo "  applying ${f}"
    kubectl --context "${CONTEXT_B}" apply -f "${f}"
  done

  echo "  Waiting for DB rollout on ${CONTEXT_B}..."
  kubectl --context "${CONTEXT_B}" -n "${NAMESPACE}" rollout status deployment "db-${STUDENT_ID}" --timeout=300s
  echo "  Waiting for app rollout on ${CONTEXT_B}..."
  kubectl --context "${CONTEXT_B}" -n "${NAMESPACE}" rollout status deployment "app-${STUDENT_ID}" --timeout=180s
else
  echo ""
  echo "[8/8] Skipping cluster B (pass --with-b to include it)"
fi

# ---- Summary ----
END_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo ""
echo "============================================================"
echo "BOOTSTRAP COMPLETE"
echo "Started:  ${START_TS}"
echo "Finished: ${END_TS}"
echo ""
echo "Cluster A:"
echo "  App URL: http://localhost:30080"
echo "  Verify:  ./scripts/verify.sh ${CONTEXT_A}"
if [ "${WITH_B}" = "true" ]; then
  echo ""
  echo "Cluster B:"
  echo "  App URL: http://localhost:30081"
  echo "  Verify:  ./scripts/verify.sh ${CONTEXT_B}"
fi
echo "============================================================"
