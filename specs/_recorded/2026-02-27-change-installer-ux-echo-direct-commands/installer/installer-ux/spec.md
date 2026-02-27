# Feature: Installer Terminal UX

Provides a polished terminal experience during installation: a welcome banner,
animated progress spinners for long-running operations, suppressed command
noise (replayed only on failure), and visually distinguished input prompts.

## Background

- The installer script (`install.sh`) is invoked directly or via `curl | sh`.
- ANSI color codes are always-on (target audience: developer terminals).

## Scenarios

<!-- DELTA:NEW -->
### Scenario: Direct command invocation echoed in dim

* *GIVEN* a command is about to be executed directly outside of `run_with_spinner`
* *WHEN* `run_direct` is called with a command
* *THEN* the script SHALL print the full command in dim color on its own line before executing it
<!-- /DELTA:NEW -->
