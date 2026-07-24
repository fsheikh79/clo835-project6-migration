# CLO835 Project 6 — Two-Cluster Data Migration

**Student:** Faizan Sheikh
**Student ID:** 114441256
**Course:** CLO835 Portable Technologies in Cloud, Fall 2026

## Overview

This project migrates a seeded MySQL 8 database from kind cluster a to a fresh kind cluster b running on the same host. Data integrity is verified with row counts and SHA256 checksums of ordered dumps. The migration is driven by Kubernetes Jobs and hostPath volumes, with no Helm, no kustomize, and no managed AWS services.

## Repository Layout

- manifests/a/ - Cluster A YAMLs (namespace, secret, configmap, DB, app)
- manifests/b/ - Cluster B YAMLs (empty DB, no seed)
- manifests/jobs/ - Dump Job (on A) and Restore Job (on B)
- scripts/ - freeze.sh, verify.sh, probe.sh, unfreeze-b.sh
- bootstrap.sh - Clean-host bootstrap for cluster A
- runbook.md - Copy-paste commands for the live demo
- ledger.md - Rehearsal log with row counts and checksums
- evidence/ - Probe logs and checksum outputs from rehearsals

## Prerequisites

- Docker
- kind v0.24.0
- kubectl v1.31+
- MySQL client
- Bash, curl, git, sha256sum, jq, tmux

## Quick Start

    export STUDENT_ID=114441256
    ./bootstrap.sh

See runbook.md for the full demo procedure.
