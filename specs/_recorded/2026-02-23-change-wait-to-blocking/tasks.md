# Tasks: change-wait-to-blocking

## Phase 2: Implementation

- [x] 2.1 Remove `_DB_READY=false` global variable and `ensure_db_ready()` function
- [x] 2.2 Add `wait_for_ready` calls in `main()` `exited` and `*` cases; remove `was_started` local
- [x] 2.3 Remove `was_started` param and wait block from `prompt_data_import`
- [x] 2.4 Remove `was_started` param and wait block from `prompt_sql_session`
- [x] 2.5 Call prompts without argument in `main()`

## Phase 3: Verification

- [x] 3.1 `shellcheck install.sh` — 0 errors/warnings
- [x] 3.2 `./tests/helpers/bats-core/bin/bats tests/start_container.bats` — 13/14 pass (test 2 pre-existing failure, unrelated)
