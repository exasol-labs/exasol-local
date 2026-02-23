# Verification Report: deferred-db-wait

Implementation completed directly in `install.sh` (retroactive plan).

## Changes Verified

- `_DB_READY=false` global flag added at top of script
- `ensure_db_ready()` helper added: calls `wait_for_ready` at most once,
  sets `_DB_READY=true` after first call
- `wait_for_ready` call removed from `case` branches in `main()`
- `was_started` flag set to `true` in `exited` and `*` cases; `false` for
  `running`
- `prompt_data_import` accepts `was_started` param; calls `ensure_db_ready`
  after user accepts, before `exapump` invocations
- `prompt_sql_session` accepts `was_started` param; calls `ensure_db_ready`
  after user accepts, before `exapump interactive`
- Both prompts invoked with `"$was_started"` in `main()`
