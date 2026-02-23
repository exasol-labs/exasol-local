# Tasks: fix-db-readiness-check

## Phase 2: Implementation

- [x] 2.1 RED: Write failing test asserting wait_for_ready uses curl, not nc
- [x] 2.2 GREEN: Replace nc -z with curl -sk in wait_for_ready
- [x] 2.3 REFACTOR: Update existing nc-based wait_for_ready tests to use curl mock

## Phase 3: Verification

- [x] 3.1 shellcheck install.sh — 0 errors/warnings
- [x] 3.2 bats tests/start_container.bats — all tests pass
