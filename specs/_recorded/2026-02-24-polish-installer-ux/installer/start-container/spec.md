# Feature: Start Exasol Container

Starts a local Exasol database container and surfaces connection details so a user can immediately connect with any SQL client.

## Background

- Docker is installed and the Docker daemon is running.
- The container is always named `exasol-local`.

## Scenarios

<!-- DELTA:NEW -->
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
<!-- /DELTA:NEW -->

<!-- DELTA:CHANGED -->
### Scenario: exapump not installed, user accepts installation

* *GIVEN* `exapump` is not available on the system PATH
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL display bullet points explaining what exapump enables (database readiness wait, CSV/Parquet import, interactive SQL sessions) and that the installer works without it
* *AND* the script SHALL prompt with a cyan `?` prefix: `? Install exapump now? [Y/n]`
* *AND* when the user confirms, the script SHALL install exapump via curl with a spinner and continue with full functionality
<!-- /DELTA:CHANGED -->
