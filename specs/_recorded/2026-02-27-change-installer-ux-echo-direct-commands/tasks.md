# Tasks: change-installer-ux-echo-direct-commands

## Phase 2: Implementation

- [x] 2.1 Add failing test `run_direct prints command in dim before running` to `tests/start_container.bats` (RED)
- [x] 2.2 Add `run_direct()` helper to `install.sh` immediately after `run_with_spinner` (GREEN)
- [x] 2.3 Replace bare `exapump interactive ...` call in `prompt_sql_session` with `run_direct exapump interactive ...`

## Phase 3: Verification

- [x] 3.1 Run `make test` — 0 failures
- [x] 3.2 Run `make lint` — 0 errors/warnings
