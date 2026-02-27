# Plan: remove-command-echo

## Summary

Removes all command-echoing behavior from `install.sh`: strips the dim `$ <cmd>` print from `run_with_spinner`, deletes the `run_direct` helper, and reverts `prompt_sql_session` to invoke `exapump interactive` directly.

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Installer Terminal UX | CHANGED | `installer/installer-ux/spec.md` |

## Implementation Tasks

1. In `install.sh`, remove the `printf "${DIM}$ %s${RESET}\n" "$*"` line from `run_with_spinner`.
2. In `install.sh`, delete the `run_direct()` function (including its doc comment).
3. In `install.sh`, revert `prompt_sql_session` to call `exapump interactive` directly instead of via `run_direct`.
4. In `tests/start_container.bats`, remove the test `run_with_spinner prints command in dim before spinner`.
5. In `tests/start_container.bats`, remove the test `run_direct prints command in dim before running`.

## Dead Code Removal

| Type | Location | Reason |
|------|----------|--------|
| Function | `install.sh` — `run_direct()` | Feature removed |
| Test | `tests/start_container.bats` — `run_with_spinner prints command in dim before spinner` | Tests removed behavior |
| Test | `tests/start_container.bats` — `run_direct prints command in dim before running` | Tests removed function |

## Verification

### Scenario Coverage

| Scenario | Test Type | Test Location | Test Name |
|----------|-----------|---------------|-----------|
| Welcome banner displayed at startup | Unit | `tests/start_container.bats` | `print_welcome outputs EXASOL banner` |
| Welcome banner line length ≤79 chars | Unit | `tests/start_container.bats` | `print_welcome lines do not exceed 79 characters` |
| Progress spinner shown for long-running steps | Unit | `tests/start_container.bats` | `run_with_spinner succeeds and calls log_success` |
| Command output suppressed; replayed on failure | Unit | `tests/start_container.bats` | `run_with_spinner fails and replays captured output` |
| Input prompts visually distinguished from informational output | Unit | `tests/start_container.bats` | `prompt_volume prints intro text and cyan prompt` |

### Manual Testing

| Feature | Command | Expected Output |
|---------|---------|-----------------|
| No command echo during spinner | Run installer and observe a spinner step | No `$ <command>` dim line appears before or during the spinner |
| No command echo before SQL session | Run installer and accept SQL session prompt | `exapump interactive` launches with no preceding dim command line |

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Unit tests | `make test` | 0 failures |
| Lint | `make lint` | 0 errors/warnings |
