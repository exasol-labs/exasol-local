# Plan: change-installer-ux-command-echo-welcome-wrap

## Summary

Adds dim-color command echo in `run_with_spinner` so users can see exactly
which system commands are being run, and reformats `print_welcome` so no
visible line exceeds 79 characters on a standard 80-column terminal.

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Installer Terminal UX | CHANGED | `installer/installer-ux/spec.md` |

## Implementation Tasks

1. In `run_with_spinner`, after `local label="$1"; shift`, add
   `printf "${DIM}$ %s${RESET}\n" "$*"` to print the command in dim color
   before the spinner starts.
2. In `print_welcome`, split the long third `printf` into multiple lines so
   each visible segment fits within 79 characters (currently ~163 chars).
3. In `tests/start_container.bats`, add a unit test verifying that
   `run_with_spinner` prints the command in dim before the spinner.
4. Update the existing `print_welcome outputs EXASOL banner` test to assert
   that no output line exceeds 79 printable characters.

## Dead Code Removal

None.

## Verification

### Scenario Coverage

| Scenario | Test Type | Test Location | Test Name |
|----------|-----------|---------------|-----------|
| Welcome banner displayed at startup | Unit | `tests/start_container.bats` | `print_welcome lines do not exceed 79 characters` |
| Command echoed in dim before execution | Unit | `tests/start_container.bats` | `run_with_spinner prints command in dim before spinner` |

### Manual Testing

| Feature | Command | Expected Output |
|---------|---------|-----------------|
| Command echo | `bash install.sh` | A dim `$ docker ...` line appears before each spinner step |
| Welcome wrap | `bash install.sh 2>&1 \| cat` | No line in the welcome banner exceeds 79 characters |

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Unit tests | `bats tests/start_container.bats` | 0 failures |
| Lint | `shellcheck install.sh` | 0 errors/warnings |
