# Tasks: add-exapump-detection

## Phase 2: Implementation (Group A — Production Code)
- [x] 2.1 Add `EXAPUMP_AVAILABLE=true` global variable at top of `install.sh`
- [x] 2.2 Add `ensure_exapump()` function to `install.sh`: check PATH, explain purpose, prompt to install, set `EXAPUMP_AVAILABLE`
- [x] 2.3 Update `main()`: call `ensure_exapump` after `detect_docker_cmd`; guard `wait_for_ready`, `prompt_data_import`, `prompt_sql_session` with `[[ "$EXAPUMP_AVAILABLE" == true ]]`
- [x] 2.4 Remove inline `command -v exapump` check from `prompt_data_import`

## Phase 2: Implementation (Group B — Tests)
- [x] 2.5 Add unit tests for `ensure_exapump` (already installed / user accepts / user declines) in `tests/start_container.bats`
- [x] 2.6 Add unit tests for skip behaviour in `main` when `EXAPUMP_AVAILABLE=false`

## Phase 3: Verification
- [x] 3.1 Run `make test` — expect 0 failures
- [x] 3.2 Run `shellcheck install.sh` — expect 0 errors/warnings
