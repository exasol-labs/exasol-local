# Plan: fix-db-readiness-check

## Problem

`wait_for_ready` polls `nc -z localhost 8563`, which succeeds as soon as the
TCP port is open. Exasol's TLS/WebSocket layer takes additional seconds to
initialize after the port opens, causing `exapump` to fail with:

```
Error: Failed to connect to localhost:8563: WebSocket error: IO error: tls handshake eof
```

## Research

The Exasol docker-db FAQ recommends checking the Admin HTTPS endpoint
(`https://localhost:8443/`) as a health signal — when 8443 responds to a
TLS connection, the database service is fully up. Port 8443 is already
mapped in our `docker run` command.

`curl -sk --max-time 2 https://localhost:8443/` is the simplest portable
check that works without any additional tools beyond `curl` (standard on
Linux).

## Solution

Replace the `nc -z` TCP-only poll with a `curl -sk` HTTPS poll against the
Admin UI port (8443). When the Admin UI responds (any HTTP status), the
database is guaranteed to be TLS-ready on 8563 too.

## Design

**Goals**
- Reliably detect full Exasol startup (TLS + WebSocket ready)
- No new runtime dependencies (`curl` is already assumed available)

**Non-Goals**
- Verifying SQL query execution during readiness check
- Falling back to nc (TCP-only check was wrong; no value in keeping it)

**Before:**
```bash
while ! nc -z localhost "$SQL_PORT" 2>/dev/null; do
```

**After:**
```bash
while ! curl -sk --max-time 2 "https://localhost:${ADMIN_PORT}/" \
    >/dev/null 2>&1; do
```

## Features

| Feature | Status | Spec |
|---------|--------|------|
| DB readiness check via HTTPS admin port | CHANGED | `installer/start-container/spec.md` |

## Verification

### Checklist

- [ ] `shellcheck install.sh` — no warnings
- [ ] `bats tests/start_container.bats` — all tests pass (update mock for curl)

### Manual Testing

1. Remove existing container: `docker rm -f exasol-local`
2. Run: `bash install.sh`
3. Accept import prompt, provide a file
4. Confirm no TLS handshake error; import succeeds

### Scenario Coverage

| Scenario | Test | Location |
|----------|------|----------|
| Database readiness via HTTPS admin port | Unit | `tests/start_container.bats` |
| Database readiness timeout | Unit | `tests/start_container.bats` |
