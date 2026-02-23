# Tasks: replace-wait-with-confd

## Phase 2: Implementation

- [x] 2.1 Replace `wait_for_ready` in `install.sh` — swap `curl` poll for `docker exec confd_client`
- [x] 2.2 Update bats tests 8 and 9 to mock `docker` instead of `curl`
- [x] 2.3 Update spec scenario "Database readiness via HTTPS admin port" → "via confd_client inside container"

## Phase 3: Verification

- [x] 3.1 `shellcheck install.sh` — 0 errors/warnings
- [x] 3.2 `bats tests/start_container.bats` — 13/14 pass (test 2 pre-existing failure, unrelated)
