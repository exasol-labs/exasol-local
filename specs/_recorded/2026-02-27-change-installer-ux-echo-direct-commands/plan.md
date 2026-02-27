# Plan: change-installer-ux-echo-direct-commands

## Summary

Introduces a `run_direct` helper that echoes any command in dim color before
running it directly (without a spinner), and replaces the bare `exapump
interactive` call in `prompt_sql_session` with `run_direct`.

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Installer Terminal UX | CHANGED | `installer/installer-ux/spec.md` |

## Implementation Tasks

1. Add `run_direct()` to `install.sh` immediately after `run_with_spinner`:
   ```bash
   run_direct() {
     printf "${DIM}$ %s${RESET}\n" "$*"
     "$@"
   }
   ```
2. In `prompt_sql_session`, replace the bare `exapump interactive ...` call
   with `run_direct exapump interactive ...`.
3. Add unit test `run_direct prints command in dim before running` to
   `tests/start_container.bats` (TDD: RED → GREEN).

## Dead Code Removal

None.

## Verification

### Scenario Coverage

| Scenario | Test Type | Test Location | Test Name |
|----------|-----------|---------------|-----------|
| Direct command invocation echoed in dim | Unit | `tests/start_container.bats` | `run_direct prints command in dim before running` |

### Manual Testing

| Feature | Command | Expected Output |
|---------|---------|-----------------|
| Direct echo | Run installer and accept SQL session prompt | A dim `$ exapump interactive ...` line appears before the session starts |

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Unit tests | `make test` | 0 failures |
| Lint | `make lint` | 0 errors/warnings |
