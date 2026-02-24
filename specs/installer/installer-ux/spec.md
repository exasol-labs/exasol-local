# Feature: Installer Terminal UX

Provides a polished terminal experience during installation: a welcome banner, animated progress spinners for long-running operations, suppressed command noise (replayed only on failure), and visually distinguished input prompts.

## Background

- The installer script (`install.sh`) is invoked directly or via `curl | sh`.
- ANSI color codes are always-on (target audience: developer terminals).

## Scenarios

### Scenario: Welcome banner displayed at startup

* *GIVEN* the installer is invoked
* *WHEN* `main` begins
* *THEN* the script SHALL print a welcome banner containing the project name `exasol-local` before any other output

### Scenario: Progress spinner shown for long-running steps

* *GIVEN* the installer is running a long-running operation (image pull, container create, container start, database readiness wait, or exapump installation)
* *WHEN* the operation is in progress
* *THEN* the script SHALL display an animated braille spinner next to a human-readable step label
* *AND* the script SHALL update the spinner animation in place without scrolling

### Scenario: Command output suppressed; replayed on failure

* *GIVEN* a long-running step (docker pull, docker run, docker start, curl install) is executing
* *WHEN* the step succeeds
* *THEN* the script SHALL NOT print the raw command output
* *AND* the script SHALL print a green ✓ line with the step label

* *WHEN* the step fails
* *THEN* the script SHALL print a red ✗ line with the step label
* *AND* the script SHALL print the captured command output to stderr

### Scenario: Input prompts visually distinguished from informational output

* *GIVEN* the installer is prompting the user for a yes/no decision
* *WHEN* any `[Y/n]` prompt is printed
* *THEN* the script SHALL prefix the prompt with a cyan `?` indicator so the user can immediately distinguish it from log lines and step status output

## Test Coverage

| Scenario | Test type | File |
|---|---|---|
| Welcome banner displayed at startup | Unit | `tests/start_container.bats` |
| Progress spinner shown for long-running steps | Unit | `tests/start_container.bats` |
| Command output suppressed; replayed on failure | Unit | `tests/start_container.bats` |
| Input prompts visually distinguished from informational output | Unit | `tests/start_container.bats` |
