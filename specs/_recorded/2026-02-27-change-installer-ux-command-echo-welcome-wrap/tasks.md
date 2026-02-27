# Tasks: change-installer-ux-command-echo-welcome-wrap

## Phase 2: Implementation

- [x] 2.1 Add dim command echo in `run_with_spinner` (install.sh)
- [x] 2.2 Fix `print_welcome` to wrap within 79 characters (install.sh)
- [x] 2.3 Add unit test: `run_with_spinner` prints command in dim before spinner
- [x] 2.4 Add unit test: `print_welcome` lines do not exceed 79 characters

## Phase 3: Verification

- [x] 3.1 Run unit tests: `bats tests/start_container.bats`
- [x] 3.2 Run linter: `shellcheck install.sh`
- [x] 3.3 Generate verification report
