# Plan: change-wait-to-blocking

## Summary

Remove the deferred/lazy `ensure_db_ready` mechanism. Call `wait_for_ready`
immediately (blocking) after starting or restarting the container, before
showing any user prompts. This simplifies the code significantly.

## Design

**Goals**
- Simple linear flow: start container → wait → prompt user
- Remove `_DB_READY` global, `ensure_db_ready()`, and `was_started` flag
- Prompt functions become stateless again (no wait logic)

**Before (deferred):**
```
start_container
↓
prompt user (while DB starts in background)
  └─ user says yes → ensure_db_ready → wait if needed → run exapump
```

**After (blocking):**
```
start_container → wait_for_ready (blocking)
↓
prompt user (DB already ready)
  └─ user says yes → run exapump immediately
```

**Trade-off:** User sees the wait message before being prompted, even if
they decline. Accepted: simplicity > micro-optimisation.

## Changes

### Code (`install.sh`)

1. Remove `_DB_READY=false` global variable
2. Remove `ensure_db_ready()` function
3. Restore `wait_for_ready` calls in `main()` `exited` and `*` cases
4. Remove `was_started` local variable from `main()`
5. Remove `was_started` param + wait block from `prompt_data_import`
6. Remove `was_started` param + wait block from `prompt_sql_session`
7. Call prompts without argument in `main()`

### Tests (`tests/start_container.bats`)

No new tests needed — the blocking wait is already covered by the existing
`wait_for_ready` unit tests (tests 8 and 9).

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Container startup wait | CHANGED | `installer/start-container/spec.md` |
| Data import wait logic | CHANGED + REMOVED | `installer/data-import/spec.md` |

## Verification

### Checklist

- [ ] `shellcheck install.sh` — 0 errors/warnings
- [ ] `./tests/helpers/bats-core/bin/bats tests/start_container.bats` — all tests pass

### Manual Testing

1. `docker rm -f exasol-local`
2. `bash install.sh`
3. Observe "Waiting for database..." appears before any prompt
4. Accept import or SQL session — no delay after accepting
