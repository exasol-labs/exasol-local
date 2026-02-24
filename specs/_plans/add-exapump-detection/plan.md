# Plan: add-exapump-detection

## Summary

At the start of `install.sh`, detect whether `exapump` is installed and, if not, explain its purpose and offer to install it. If the user declines, skip the database readiness wait, data-import prompt, and SQL-session prompt.

## Design

### Goals / Non-Goals

- Goals
    - Detect `exapump` once at startup rather than inline in individual functions
    - Give the user a clear explanation of what exapump enables before asking to install it
    - Make the skip-if-unavailable behaviour consistent and explicit
- Non-Goals
    - Changing the exapump install mechanism itself
    - Providing a fallback readiness check when exapump is absent
    - Supporting Windows or macOS

### Architecture

```
main()
  │
  ├─ 1. detect_docker_cmd
  ├─ 2. ensure_exapump         ← NEW: check/install exapump, set EXAPUMP_AVAILABLE
  ├─ 3. pull image if needed
  ├─ 4. create / start container
  ├─ 5. wait_for_ready         ← skipped if EXAPUMP_AVAILABLE=false
  ├─ 6. prompt_data_import     ← skipped if EXAPUMP_AVAILABLE=false
  ├─ 7. prompt_sql_session     ← skipped if EXAPUMP_AVAILABLE=false
  └─ 8. print_connection_info
```

### Design Patterns

| Pattern | Where | Why |
|---------|-------|-----|
| Feature flag (global var) | `EXAPUMP_AVAILABLE` | Single decision point; avoids repeated inline checks |
| Early detection | `ensure_exapump()` at top of `main()` | Consistent UX; one-time prompt before long-running Docker work |

### Trade-offs

| Decision | Alternatives Considered | Rationale |
|----------|------------------------|-----------|
| Global `EXAPUMP_AVAILABLE` flag | Re-check `command -v exapump` at each call site | Single check is simpler; avoids race conditions after install |
| Skip silently when unavailable | Print warning at each skipped step | Less noise; user already acknowledged the skip when declining |
| Remove inline `command -v exapump` checks from prompts | Keep them as fallback | The early check makes them redundant; removing keeps code DRY |

## Features

| Feature | Status | Spec |
|---------|--------|------|
| exapump detection and install offer | NEW | `installer/start-container/spec.md` |
| Skip features when exapump unavailable | CHANGED | `installer/data-import/spec.md` |

## Implementation Tasks

1. Add `EXAPUMP_AVAILABLE=true` global variable at the top of `install.sh`
2. Add `ensure_exapump()` function: check PATH, show purpose overview, prompt to install, set `EXAPUMP_AVAILABLE`
3. Update `main()`: call `ensure_exapump` after `detect_docker_cmd`; wrap `wait_for_ready`, `prompt_data_import`, `prompt_sql_session` in `[[ "$EXAPUMP_AVAILABLE" == true ]]` guards
4. Remove inline `command -v exapump` checks from `prompt_data_import` and `prompt_sql_session`
5. Add unit tests for `ensure_exapump` (already installed, user accepts install, user declines install) in `tests/start_container.bats`
6. Add unit tests for the skip behaviour in `main` when `EXAPUMP_AVAILABLE=false`

## Dead Code Removal

| Type | Location | Reason |
|------|----------|--------|
| Inline exapump check | `prompt_data_import` in `install.sh` | Replaced by `ensure_exapump()` early detection |
| Inline exapump check | `prompt_sql_session` in `install.sh` | Replaced by `ensure_exapump()` early detection |
| Spec scenario | `installer/data-import` — "exapump not installed" | Superseded by early detection; user can no longer reach prompt without exapump |
| Spec scenario | `installer/data-import` — "exapump not installed (SQL session)" | Same reason |

## Verification

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Unit tests | `make test` | 0 failures |
| Lint | `shellcheck install.sh` | 0 errors/warnings |

### Manual Testing

| Feature | Test Steps | Expected Result |
|---------|------------|-----------------|
| exapump already installed | Run `bash install.sh` with exapump on PATH | No install prompt; proceeds with wait + prompts |
| exapump absent, accept install | Run `bash install.sh` without exapump; enter Y at install prompt | exapump installed; proceeds with wait + prompts |
| exapump absent, decline install | Run `bash install.sh` without exapump; enter N at install prompt | DB wait skipped; no data import or SQL session prompt; connection info printed |

### Scenario Verification

| Scenario | Test Type | Test Location |
|----------|-----------|---------------|
| exapump already installed | Unit | `tests/start_container.bats` |
| exapump not installed, user accepts installation | Unit | `tests/start_container.bats` |
| exapump not installed, user declines installation | Unit | `tests/start_container.bats` |
| exapump not available - all prompts skipped | Unit | `tests/start_container.bats` |
| Database readiness via exapump SELECT 1 (exapump available) | Unit | `tests/start_container.bats` |
