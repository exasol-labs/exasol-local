# Tasks: add-ecr-login-workaround

## Phase 2: Implementation

- [x] 2.1 In `install.sh`, inside `detect_platform()` on the macOS/arm64 branch, after setting `IMAGE` and `DEFAULT_EXA_VOLUME`, add ECR login call with prominent workaround comment and full output suppression (`>/dev/null 2>&1 || true`)
- [x] 2.2 Add unit test to `tests/start_container.bats` verifying ECR login is called on Darwin
- [x] 2.3 Add unit test to `tests/start_container.bats` verifying ECR login is NOT called on Linux

## Phase 3: Verification

- [x] 3.1 Run unit tests: `bats tests/start_container.bats` — 0 failures
- [x] 3.2 Run lint: `shellcheck install.sh` — 0 errors/warnings
- [x] 3.3 Scenario coverage audit
