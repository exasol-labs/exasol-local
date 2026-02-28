# Tasks: add-mac-platform-detection

## Phase 2: Implementation

- [x] 2.1 Write failing unit tests for `detect_platform()` in `tests/start_container.bats` (TDD RED step)
- [x] 2.2 Add `detect_platform()` function to `install.sh`; remove hardcoded `IMAGE=` variable; call `detect_platform` in `main()` (TDD GREEN step)
- [x] 2.3 Update `specs/mission.md`: add macOS to scope, remove Admin UI from Core Capabilities, update Constraints

## Phase 3: Verification

- [x] 3.1 Run unit tests: `bats tests/start_container.bats`
- [x] 3.2 Run linter: `shellcheck install.sh`
