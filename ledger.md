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

## Notes

- R1: baseline pipeline test with 500 seeded rows.
- R2: added 3 TWIST rows before freeze to simulate instructor twist; SHA256 changed accordingly and B received all TWIST rows. Downtime dropped 19s from R1 due to familiarity with the runbook.
