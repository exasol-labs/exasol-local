# Plan: replace-wait-with-confd

## Summary

Replace the `curl`-based HTTPS poll in `wait_for_ready` with a
`docker exec confd_client` check that verifies the Exasol DB service
is truly running and connectable inside the container.

## Design

**Before:**
```bash
while ! curl -sk --max-time 2 "https://localhost:${ADMIN_PORT}/" ...
```

**After:**
```bash
while ! $DOCKER exec "$CONTAINER_NAME" bash -c \
  '[[ "$(confd_client --json db_info db_name: DB1 2>/dev/null | \
    jq -r '"'"'select (.state == "running" and .connectible == "Yes") | true'"'"')" == "true" ]]' \
  2>/dev/null
```

The container ID/name is taken from `$CONTAINER_NAME` (already available as a global).
`$DOCKER` is used so sudo is handled correctly.

**Why:** The HTTPS admin port can respond before the DB service itself is
ready to accept connections. `confd_client` queries the internal DB state
directly and returns only when state is `running` AND connectible is `Yes`.

## Changes

### Code (`install.sh`)

1. Replace body of `wait_for_ready` — swap `curl` poll for `docker exec confd_client`
2. Remove `ADMIN_PORT` from the polling logic (no longer needed in `wait_for_ready`;
   still kept as a global for `print_connection_info` and `open_admin_ui`)

### Tests (`tests/start_container.bats`)

3. Update test 8 ("wait_for_ready succeeds when port is immediately available"):
   - Change mock from `curl() { return 0; }` to `docker() { return 0; }`
   - Update test name to reflect new mechanism
4. Update test 9 ("wait_for_ready exits 1 on timeout"):
   - Change mock from `curl() { return 1; }` to `docker() { return 1; }`

### Spec (`specs/installer/start-container/spec.md`)

5. Rename and rewrite "Database readiness via HTTPS admin port" scenario:
   - New name: "Database readiness via confd_client inside container"
   - Replace curl/HTTPS steps with docker exec / confd_client steps

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Container startup wait | CHANGED | `installer/start-container/spec.md` |

## Verification

### Checklist

- [ ] `shellcheck install.sh` — 0 errors/warnings
- [ ] `./tests/helpers/bats-core/bin/bats tests/start_container.bats` — all tests pass

## Parallelization

All tasks are sequential (tests depend on code; spec is independent but small).
