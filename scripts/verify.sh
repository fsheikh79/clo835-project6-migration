#!/usr/bin/env bash
# verify.sh - Print row count and SHA256 of the ordered dump for a given kind context.
# Task 7 of Project 6.
# Usage: ./scripts/verify.sh kind-a
#        ./scripts/verify.sh kind-b

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <context>   (e.g., $0 kind-a)"
  exit 1
fi

CONTEXT="$1"
STUDENT_ID="${STUDENT_ID:-114441256}"
NAMESPACE="migrate-${STUDENT_ID}"
DB_DEPLOY="db-${STUDENT_ID}"

echo "=== VERIFY on context: ${CONTEXT} ==="

echo ""
echo "--- Row count ---"
kubectl --context "${CONTEXT}" -n "${NAMESPACE}" exec deploy/"${DB_DEPLOY}" -- \
  bash -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -N -B -e "SELECT COUNT(*) FROM appdb.records;" 2>/dev/null'

echo ""
echo "--- First 3 rows (proof rows contain student ID) ---"
kubectl --context "${CONTEXT}" -n "${NAMESPACE}" exec deploy/"${DB_DEPLOY}" -- \
  bash -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT * FROM appdb.records ORDER BY id LIMIT 3;" 2>/dev/null'

echo ""
echo "--- SHA256 of ordered dump ---"
kubectl --context "${CONTEXT}" -n "${NAMESPACE}" exec deploy/"${DB_DEPLOY}" -- \
  bash -c 'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" \
    --order-by-primary --skip-dump-date --skip-comments \
    --no-tablespaces --set-gtid-purged=OFF --single-transaction \
    --databases appdb 2>/dev/null' | sha256sum | awk '{print $1}'

echo ""
echo "=== VERIFY complete for ${CONTEXT} ==="
