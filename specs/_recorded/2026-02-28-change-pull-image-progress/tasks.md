# Tasks: change-pull-image-progress

## Phase 2: Implementation

- [x] 2.1 Remove `run_with_spinner` call from `pull_image()` and replace with direct `$DOCKER pull "$IMAGE"` invocation
- [x] 2.2 Verify `log_info` context lines before pull are preserved
- [x] 2.3 Add unit test: `pull_image calls docker pull directly without spinner`

## Phase 3: Verification

- [x] 3.1 Run unit tests (`make test`) — 0 failures
- [x] 3.2 Run lint (`make lint`) — 0 errors/warnings
