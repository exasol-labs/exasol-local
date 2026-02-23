# Plan: deferred-db-wait

## Summary

Defer the `wait_for_ready` call so the database readiness poll only blocks
when the user actually needs the DB (i.e. accepts the import or SQL session
prompt). If the user declines both prompts the script exits without waiting.
An `ensure_db_ready` guard (backed by `_DB_READY` flag) ensures the poll
runs at most once even if both prompts are accepted.

## Changes

### installer/start-container
- **CHANGED** `Container starts from scratch`: remove the immediate
  wait-for-ready step; waiting is now lazy.
- **CHANGED** `Stopped container exists`: same.

### installer/data-import
- **CHANGED** `Successful CSV import`: precondition no longer assumes DB
  is ready at prompt time; wait happens inside the function after user
  accepts.
- **CHANGED** `Successful Parquet import`: same.
- **CHANGED** `User accepts SQL session with Enter (default Y)`: wait
  happens before `exapump interactive` when container was just started.
- **NEW** `DB wait deferred until user accepts import`
- **NEW** `DB wait deferred until user accepts SQL session`
- **NEW** `DB wait runs at most once`
- **NEW** `DB wait skipped when both prompts declined`
