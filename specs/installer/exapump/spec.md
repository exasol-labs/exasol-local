# Feature: exapump

Manages database readiness polling and the optional exapump CLI tool for data import and SQL sessions.

## Background

- The Exasol container is started.
- exapump is an optional CLI; the installer can work without it.

## Scenarios

### Scenario: Database readiness timeout

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *WHEN* `install.sh` is executed
* *AND* the database does not become ready within 120 seconds
* *THEN* the script SHALL print an error message indicating the startup timed out
* *AND* the script SHALL exit with a non-zero status code

### Scenario: Database readiness via exapump SELECT 1

* *GIVEN* the Exasol container has been started
* *AND* exapump is available (was pre-installed or installed during startup)
* *WHEN* `wait_for_ready` polls for database readiness
* *THEN* the script SHALL run `exapump sql "SELECT 1" --dsn exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0`
* *AND* the script SHALL consider the database ready when `exapump sql` exits with status 0
* *AND* the script SHALL print "Database is ready." once the check succeeds

### Scenario: exapump already installed

* *GIVEN* `exapump` is available on the system PATH
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL NOT prompt the user to install exapump
* *AND* the script SHALL proceed with full functionality (DB readiness wait, data import, SQL session prompts)

### Scenario: exapump not installed, user accepts installation

* *GIVEN* `exapump` is not available on the system PATH
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL display bullet points explaining what exapump enables (database readiness wait, CSV/Parquet import, interactive SQL sessions) and that the installer works without it
* *AND* the script SHALL prompt with a cyan `?` prefix: `? Install exapump now? [Y/n]`
* *AND* when the user confirms, the script SHALL install exapump via curl with a spinner and continue with full functionality

### Scenario: exapump not installed, user declines installation

* *GIVEN* `exapump` is not available on the system PATH
* *WHEN* `install.sh` prompts "Install exapump now? [Y/n]" and the user enters "n" or "N"
* *THEN* the script SHALL skip database readiness wait, data import prompt, and SQL session prompt
* *AND* the script SHALL print connection details to stdout

## Test Coverage

| Scenario | Test type | File |
|---|---|---|
| Database readiness timeout | Unit | `tests/start_container.bats` |
| Database readiness via exapump SELECT 1 | Unit | `tests/start_container.bats` |
| exapump already installed | Unit | `tests/start_container.bats` |
| exapump not installed, user accepts installation | Unit | `tests/start_container.bats` |
| exapump not installed, user declines installation | Unit | `tests/start_container.bats` |
