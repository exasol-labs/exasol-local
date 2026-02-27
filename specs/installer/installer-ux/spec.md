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
* *AND* every visible line in the welcome message SHALL NOT exceed 79 characters so it does not wrap on a standard 80-column terminal

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

### Scenario: Command echoed in dim before execution

* *GIVEN* a long-running step is about to execute via `run_with_spinner`
* *WHEN* `run_with_spinner` is called with a label and a command
* *THEN* the script SHALL print the full command in dim color on its own line before starting the spinner

### Scenario: Direct command invocation echoed in dim

* *GIVEN* a command is about to be executed directly outside of `run_with_spinner`
* *WHEN* `run_direct` is called with a command
* *THEN* the script SHALL print the full command in dim color on its own line before executing it

## Test Coverage

| Scenario | Test type | File |
|---|---|---|
| Welcome banner displayed at startup | Unit | `tests/start_container.bats` |
| Progress spinner shown for long-running steps | Unit | `tests/start_container.bats` |
| Command output suppressed; replayed on failure | Unit | `tests/start_container.bats` |
| Input prompts visually distinguished from informational output | Unit | `tests/start_container.bats` |
| Command echoed in dim before execution | Unit | `tests/start_container.bats` |
| Direct command invocation echoed in dim | Unit | `tests/start_container.bats` |
