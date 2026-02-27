# Tasks: remove-command-echo

## Phase 2: Implementation

- [x] 2.1 Remove `printf "${DIM}$ %s${RESET}\n" "$*"` line from `run_with_spinner` in `install.sh`
- [x] 2.2 Delete `run_direct()` function and its doc comment from `install.sh`
- [x] 2.3 Revert `prompt_sql_session` to call `exapump interactive` directly (remove `run_direct` wrapper)
- [x] 2.4 Remove test `run_with_spinner prints command in dim before spinner` from `tests/start_container.bats`
- [x] 2.5 Remove test `run_direct prints command in dim before running` from `tests/start_container.bats`

## Phase 3: Verification

- [x] 3.1 Run `make test` — 0 failures
- [x] 3.2 Run `make lint` — 0 errors/warnings
