# Tasks: add-docker-preflight-checks

## Phase 2: Implementation

- [x] 2.1 Add failing tests (RED): `detect_docker_cmd exits when docker not installed`, `detect_docker_cmd starts daemon when not running`, `detect_docker_cmd exits when daemon cannot be started` in `tests/start_container.bats`
- [x] 2.2 Add `check_docker_installed()` to `install.sh` (before `detect_docker_cmd`)
- [x] 2.3 Add `start_docker_daemon()` to `install.sh` (before `detect_docker_cmd`)
- [x] 2.4 Refactor `detect_docker_cmd()` in `install.sh` to call both helpers and handle daemon start

## Phase 3: Verification

- [x] 3.1 Run unit tests: `make test`
- [x] 3.2 Run linter: `make lint`

## Code Review Fixes

- [x] R1 Fix BLOCKER: rewrite 3 new tests to use real `detect_docker_cmd` via `source "$SCRIPT"` (not inline copies)
- [x] R2 Fix WARNING: update stale existing test 2 to use real `detect_docker_cmd`
- [x] R3 Fix WARNING: remove doc comments from private helpers in `install.sh`
- [x] R4 Fix WARNING: distinguish "daemon started but unreachable" from "daemon failed to start" in error message
