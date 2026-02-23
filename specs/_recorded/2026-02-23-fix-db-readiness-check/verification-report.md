# Verification Report: fix-db-readiness-check

## Summary

All plan objectives met. The `wait_for_ready` function now polls the Admin
HTTPS endpoint (`https://localhost:8443/`) instead of the raw TCP port via
`nc -z`, ensuring the database's TLS/WebSocket layer is fully up before
`exapump` attempts to connect.

## Changes

### `install.sh`

`wait_for_ready`: replaced `nc -z localhost "$SQL_PORT"` with
`curl -sk --max-time 2 "https://localhost:${ADMIN_PORT}/"`.
Updated echo message to remove the SQL port reference.

### `tests/start_container.bats`

Updated the two `wait_for_ready` tests to mock `curl()` instead of `nc()`.

## Verification Results

### shellcheck

```
$ shellcheck install.sh
(no output — exit 0)
```

✓ 0 errors, 0 warnings

### bats

```
$ ./tests/helpers/bats-core/bin/bats tests/start_container.bats
1..14
ok 1 detect_docker_cmd sets DOCKER=docker when docker info succeeds
not ok 2 detect_docker_cmd sets DOCKER='sudo docker' when docker info fails  ← pre-existing
ok 3 check_image_cached returns 0 when image exists
ok 4 check_image_cached returns 1 when image is absent
ok 5 check_container_state outputs 'running' when container is running
ok 6 check_container_state outputs 'exited' when container is stopped
ok 7 check_container_state outputs empty string when container does not exist
ok 8 wait_for_ready succeeds when port is immediately available
ok 9 wait_for_ready exits 1 on timeout
ok 10 print_connection_info prints DSN, user, and password
ok 11 script pulls image and creates container when starting from scratch
ok 12 script does not pull image when already cached
ok 13 script skips container creation when already running
ok 14 script restarts stopped container without docker run
```

✓ 13/14 pass
⚠ Test 2 is a pre-existing macOS environment failure (function mock for
`docker()` is shadowed by the real Docker Desktop binary). Not introduced
by this plan; unrelated to readiness check logic.

### Scenario Coverage

| Scenario | Test # | Result |
|----------|--------|--------|
| Database readiness via HTTPS admin port | 8 | ✓ pass |
| Database readiness timeout | 9 | ✓ pass |
