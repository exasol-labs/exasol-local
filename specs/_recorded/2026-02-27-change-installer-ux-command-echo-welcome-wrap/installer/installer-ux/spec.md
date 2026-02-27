# Feature: Installer Terminal UX

Provides a polished terminal experience during installation: a welcome banner,
animated progress spinners for long-running operations, suppressed command
noise (replayed only on failure), and visually distinguished input prompts.

## Background

- The installer script (`install.sh`) is invoked directly or via `curl | sh`.
- ANSI color codes are always-on (target audience: developer terminals).

## Scenarios

<!-- DELTA:CHANGED -->
### Scenario: Welcome banner displayed at startup

* *GIVEN* the installer is invoked
* *WHEN* `main` begins
* *THEN* the script SHALL print a welcome banner containing the project name `exasol-local` before any other output
* *AND* every visible line in the welcome message SHALL NOT exceed 79 characters so it does not wrap on a standard 80-column terminal
<!-- /DELTA:CHANGED -->

<!-- DELTA:NEW -->
### Scenario: Command echoed in dim before execution

* *GIVEN* a long-running step is about to execute via `run_with_spinner`
* *WHEN* `run_with_spinner` is called with a label and a command
* *THEN* the script SHALL print the full command in dim color on its own line before starting the spinner
<!-- /DELTA:NEW -->
