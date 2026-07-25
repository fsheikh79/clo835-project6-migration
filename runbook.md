# CLO835 Project 6 — Runbook

**Student:** Faizan Sheikh (114441256)
**Purpose:** Copy-paste commands for the live demo. Follow top to bottom.

Every step includes what to **narrate** first (prediction), then the **command**, then what to **verify**.

---

## 0. Pre-demo setup (done before the 10-minute window)

Cluster A must already be running with 500 rows seeded. Cluster B is optional at this stage but easier to have ready.

```bash
export STUDENT_ID=114441256
./bootstrap.sh --with-b
```

Confirm final commit:

```bash
git log -1
```

Announce the frozen commit hash to the instructor. The demo runs from that commit.

---

## 1. Prove cluster A seed data

**Narrate:** "First I'll verify cluster A is seeded with 500 rows, each stamped with my student ID 114441256, and compute the SHA256 of an ordered dump."

```bash
./scripts/verify.sh kind-a
```

**Verify on screen:**
- Row count: **500**
- Sample rows contain `seed-114441256-*`
- SHA256 printed at the bottom

Also open in browser: **http://localhost:30080** — show the live page with Cluster: A, Student ID 114441256, Row count 500.

---

## 2. Instructor twist — capture surprise rows

**Narrate:** "The instructor is about to insert surprise rows into cluster A. My pipeline dumps the whole table at freeze time, so whatever they insert must appear on cluster B after migration."

Wait for the instructor to run their insert script. They will announce a marker string (for example `TWIST-abc123`).

**After the twist, re-verify to show the new count:**

```bash
./scripts/verify.sh kind-a
```

**Verify:** row count is now `500 + N` where N is the instructor's insert count. Also verify the marker rows are present:

```bash
kubectl --context kind-a -n migrate-114441256 exec deploy/db-114441256 -- \
  bash -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT * FROM appdb.records WHERE payload LIKE '\''%TWIST%'\'';" 2>/dev/null'
```

(Substitute the actual marker string the instructor announced.)

---

## 3. Start the downtime probe (second terminal)

**Narrate:** "I'll start a probe against cluster A's URL — one HTTP request per second, timestamped, logged to evidence/probe.log. The gap between the last SUCCESS and the next SUCCESS on cluster B will be my measured downtime."

**Open a second terminal, cd into the repo:**

```bash
cd ~/clo835-project6-migration
./scripts/probe.sh http://localhost:30080
```

**Verify:** one SUCCESS line per second appearing.

---

## 4. Confirm cluster B is empty

**Narrate:** "Cluster B is running but has no data yet — it's ready to receive the migration."

```bash
./scripts/verify.sh kind-b
```

**Verify:** row count is `0`. SHA256 differs from A (empty schema hash).

Also open **http://localhost:30081** — should show Cluster: B, Row count: 0.

---

## 5. Freeze writes on cluster A

**Narrate:** "Freezing writes on A by scaling the app deployment to 0 replicas. This prevents any new inserts between now and the dump, so the dump captures the exact table state at this moment."

```bash
./scripts/freeze.sh
```

**Verify:**
- Deployment shows `0/0` READY
- The probe (second terminal) starts showing FAILURE lines
- Browser at http://localhost:30080 no longer loads

---

## 6. Run the dump Job on cluster A

**Narrate:** "The dump Job will run mysqldump with --order-by-primary and --skip-dump-date so the output is deterministic. It writes to /mnt/migrate/dump.sql inside the pod, which maps to /tmp/migrate-114441256/dump.sql on the host."

```bash
kubectl --context kind-a apply -f manifests/jobs/dump-job.yaml
kubectl --context kind-a -n migrate-114441256 wait --for=condition=complete job/dump-114441256 --timeout=120s
```

**Verify the dump landed:**

```bash
ls -la /tmp/migrate-114441256/dump.sql
sha256sum /tmp/migrate-114441256/dump.sql
```

**Read the SHA256 aloud.** This is the value that must match on cluster B.

Also print the row count from the Job logs:

```bash
kubectl --context kind-a -n migrate-114441256 logs -l app=dump-114441256 | grep "Row count"
```

---

## 7. Run the restore Job on cluster B

**Narrate:** "The restore Job runs on cluster B, mounts the same host directory via hostPath, and loads /mnt/migrate/dump.sql into cluster B's MySQL."

```bash
kubectl --context kind-b apply -f manifests/jobs/restore-job.yaml
kubectl --context kind-b -n migrate-114441256 wait --for=condition=complete job/restore-114441256 --timeout=120s
```

**Verify:**

```bash
kubectl --context kind-b -n migrate-114441256 logs -l app=restore-114441256 | tail -20
```

Look for "Row count on cluster B after restore" — should equal cluster A's count.

---

## 8. Verify BOTH sides match — the pass bar moment

**Narrate:** "Now I'll compute the row count and SHA256 on both clusters. They must be identical byte-for-byte."

```bash
./scripts/verify.sh kind-a
```

```bash
./scripts/verify.sh kind-b
```

**Verify on screen:**
- Row count A == Row count B == (500 + twist inserts)
- SHA256 A == SHA256 B

**Read both SHA256s aloud, character by character if needed.** This is what the instructor is watching for.

---

## 9. Prove instructor's marker rows survived

**Narrate:** "The instructor inserted rows I never saw before this demo. If my pipeline works, those rows are on cluster B now."

```bash
kubectl --context kind-b -n migrate-114441256 exec deploy/db-114441256 -- \
  bash -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT * FROM appdb.records WHERE payload LIKE '\''%TWIST%'\'';" 2>/dev/null'
```

(Substitute the actual marker string the instructor announced.)

**Verify:** all instructor-inserted rows visible on cluster B.

---

## 10. Cut traffic to cluster B

**Narrate:** "I'll now point the probe at cluster B's URL. Since the app on B is already running, the probe should immediately succeed."

**In the second (probe) terminal:** press Ctrl+C, then run:

```bash
./scripts/probe.sh http://localhost:30081
```

**Verify:** SUCCESS lines appear immediately for `localhost:30081`.

Also refresh **http://localhost:30081** in browser — shows cluster B with the new row count.

---

## 11. Stop probe and read downtime

**Narrate:** "Downtime equals the failure window in the probe log — from the moment freeze took effect on cluster A to the moment cluster B started serving."

**In the probe terminal:** Ctrl+C.

**In the main terminal:**

```bash
echo "First FAILURE:"
grep FAILURE evidence/probe.log | head -1

echo "Last FAILURE before switch to B:"
grep "FAILURE.*30080" evidence/probe.log | tail -1

echo "First SUCCESS on B:"
grep "SUCCESS.*30081" evidence/probe.log | head -1

echo "Downtime (FAILURE seconds against A):"
grep -c "FAILURE.*30080" evidence/probe.log
```

**Read the downtime aloud.** Must be under 10 minutes (600 seconds).

---

## 12. Append final entry to ledger.md

**Narrate:** "I'll now log this demo run to my ledger, matching the format of my rehearsal entries."

Copy the row-count, SHA256, and downtime into ledger.md:

```bash
# Edit ledger.md, add a row like:
# | DEMO | 2026-07-26 | 500+N | <sha> | 500+N | <sha> | <downtime> |
nano ledger.md
```

Commit:

```bash
git add ledger.md
git commit -m "Demo run entry"
```

(Do NOT push after final commit hash is declared — the frozen hash is your submission.)

---

## Rollback procedure (in case restore fails)

If cluster B's restore does not produce matching checksums:

```bash
./scripts/unfreeze-b.sh    # confirm B is up (nothing to lose)

# OR rollback to A:
kubectl --context kind-a -n migrate-114441256 scale deployment app-114441256 --replicas=2
kubectl --context kind-a -n migrate-114441256 rollout status deployment app-114441256
```

Then investigate the mismatch:
- Compare SHA256s of both dumps
- `diff` the two dumps
- Check restore Job logs for any warnings

---

## Endpoints (for reference during demo)

- Cluster A app: http://localhost:30080
- Cluster B app: http://localhost:30081
- Host dump file: /tmp/migrate-114441256/dump.sql
- Namespace on both clusters: migrate-114441256

