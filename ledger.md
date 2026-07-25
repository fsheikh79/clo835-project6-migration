# Rehearsal Ledger — Project 6

**Student:** Faizan Sheikh (114441256)

Each rehearsal migrates data from cluster A to cluster B and verifies:

- Row counts match on both sides
- SHA256 of ordered dumps match byte-for-byte
- Downtime measured from probe.log is under the 10-minute pass bar

| Rehearsal | Date (UTC) | Row count A | SHA256 A | Row count B | SHA256 B | Downtime (s) |
|-----------|------------|-------------|----------|-------------|----------|--------------|
| 1 | 2026-07-24 | 500 | 6ff652fd25cf43d4a10ce247395ef9413c58e0895c02f637e08bc6618bdcae43 | 500 | 6ff652fd25cf43d4a10ce247395ef9413c58e0895c02f637e08bc6618bdcae43 | 106 |
| 2 | 2026-07-25 | 503 | e789413886c4a8382cac89338339ed8ce7f9781d469140f6d66aa8d150ba3974 | 503 | e789413886c4a8382cac89338339ed8ce7f9781d469140f6d66aa8d150ba3974 | 87 |
| 3 | 2026-07-25 | 505 | 92c62e3e479c22d466e79f2223b214181b3021723bf59ddf1b23eda00b993f53 | 505 | 92c62e3e479c22d466e79f2223b214181b3021723bf59ddf1b23eda00b993f53 | 69 |

## Notes

- **R1**: baseline pipeline test with 500 seeded rows.
- **R2**: added 3 TWIST rows before freeze to simulate instructor twist; SHA256 changed accordingly and B received all TWIST rows. Downtime dropped 19s from R1 due to familiarity with the runbook.
- **R3**: added 5 SURPRISE rows with different marker string; SHA256 changed again and all 5 rows arrived on cluster B. Downtime dropped a further 18s (R1: 106s → R2: 87s → R3: 69s) — the trend proves rehearsal shortens human command latency, which dominates the total. Interesting side note: the baseline SHA256 on cluster A had changed from R1 due to MySQL's AUTO_INCREMENT counter not rewinding after DELETE (see oral question 5 notes).

## Pass bars — evidence of compliance

- ✅ Row counts and SHA256s match across A and B in every rehearsal
- ✅ Marker/twist rows always survive migration (proven by R2's TWIST and R3's SURPRISE)
- ✅ Downtime under 10 minutes (all runs under 2 minutes)
- ✅ 3 pre-submission rehearsal entries with reproducible method
