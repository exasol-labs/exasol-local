# Plan: replace-confd-with-exapump

## Summary

Replace the `docker exec confd_client` readiness check in `wait_for_ready`
with `exapump sql "SELECT 1"` against the actual database DSN. This removes
the dependency on container internals and verifies the DB is reachable from
the host's perspective.

## Design

**Before:**
```bash
docker exec $CONTAINER_NAME bash -c 'confd_client ... | jq ...'
```

**After:**
```bash
exapump sql "SELECT 1" \
  --dsn 'exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0'
```

TLS validation is bypassed via `validateservercertificate=0` (same DSN
format already used throughout the script for exapump invocations).

## Changes

### Code (`install.sh`)

1. Replace body of `wait_for_ready` — remove `docker exec confd_client`; run
   `exapump sql "SELECT 1" --dsn ...` instead

### Tests (`tests/start_container.bats`)

2. Update test 8: mock `exapump` returning 0 (success)
3. Update test 9: mock `exapump` returning 1 (timeout)

### Spec (`specs/installer/start-container/spec.md`)

4. Rename "Database readiness via confd_client inside container" →
   "Database readiness via exapump SELECT 1"; update steps
5. Fix stale test coverage row label

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Container startup wait | CHANGED | `installer/start-container/spec.md` |

## Verification

- [ ] `shellcheck install.sh` — 0 errors/warnings
- [ ] `bats tests/start_container.bats` — all tests pass
