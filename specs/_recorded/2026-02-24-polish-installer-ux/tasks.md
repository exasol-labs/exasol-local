# Tasks: polish-installer-ux

## Group A — New helpers
- [x] 1. Add ANSI color constants and icon constants (after globals, before first function)
- [x] 2. Add `_SPINNER_CHARS` array and `_SPINNER_PID=""` global
- [x] 3. Add `log_step`, `log_success`, `log_error` functions
- [x] 4. Add `start_spinner` and `stop_spinner` functions
- [x] 5. Add `run_with_spinner <label> <cmd…>` function
- [x] 6. Add `print_welcome` function

## Group B — Production updates
- [x] 7. Update `ensure_exapump`: bullet-point copy, formatted prompt, wrap curl in `run_with_spinner`
- [x] 8. Update `pull_image`: replace echo+docker with `run_with_spinner`
- [x] 9. Update `create_container`: replace echo+docker run with `run_with_spinner`
- [x] 10. Update `start_existing`: replace echo+docker start with `run_with_spinner`
- [x] 11. Update `wait_for_ready`: inline braille spinner with elapsed seconds
- [x] 12. Update `prompt_data_import`: cyan `?` prompt prefix, wrap exapump commands in `run_with_spinner`
- [x] 13. Update `prompt_sql_session`: cyan `?` prompt prefix
- [x] 14. Update `print_connection_info`: bold header + dim labels
- [x] 15. Update `main`: add `print_welcome` call at top

## Group C — Tests
- [x] 16. Update unit tests in `tests/start_container.bats`:
         - Update output assertions for changed functions
         - Add tests for `log_success`, `log_error`, `run_with_spinner` (success + failure paths)
         - Add test for `print_welcome`

## Phase 3: Verification
- [x] V1. Run `make test` — 23/23 passed
- [x] V2. Run `shellcheck install.sh` — 0 errors/warnings
