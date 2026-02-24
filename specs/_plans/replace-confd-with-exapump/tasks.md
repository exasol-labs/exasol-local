# Tasks: replace-confd-with-exapump

## Phase 2: Implementation

- [x] 2.1 Replace `wait_for_ready` in `install.sh` — use `exapump sql "SELECT 1"` instead of `docker exec confd_client`
- [x] 2.2 Update bats test 8 — mock `exapump` returning 0
- [x] 2.3 Update bats test 9 — mock `exapump` returning 1
- [x] 2.4 Update spec scenario and test coverage row in `specs/installer/start-container/spec.md`

## Phase 3: Verification

- [x] 3.1 `shellcheck install.sh` — 0 errors/warnings
- [x] 3.2 `bats tests/start_container.bats` — 13/14 pass (test 2 pre-existing failure, unrelated)
