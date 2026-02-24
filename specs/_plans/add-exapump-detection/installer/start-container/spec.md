# Feature: Start Exasol Container

Starts a local Exasol database container and surfaces connection details so a user can immediately connect with any SQL client.

## Background

- Docker is installed and the Docker daemon is running.
- The container is always named `exasol-local`.

## Scenarios

<!-- DELTA:NEW -->
### Scenario: exapump already installed

* *GIVEN* `exapump` is available on the system PATH
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL NOT prompt the user to install exapump
* *AND* the script SHALL proceed with full functionality (DB readiness wait, data import, SQL session prompts)

### Scenario: exapump not installed, user accepts installation

* *GIVEN* `exapump` is not available on the system PATH
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL display a brief overview of exapump's purpose: waiting for the database to be ready, loading CSV or Parquet files, and starting interactive SQL sessions
* *AND* the script SHALL prompt "Install exapump now? [Y/n]"
* *AND* when the user confirms (Y or Enter), the script SHALL run `curl -fsSL https://raw.githubusercontent.com/exasol-labs/exapump/main/install.sh | sh`
* *AND* the script SHALL continue with full functionality after installation

### Scenario: exapump not installed, user declines installation

* *GIVEN* `exapump` is not available on the system PATH
* *WHEN* `install.sh` prompts "Install exapump now? [Y/n]" and the user enters "n" or "N"
* *THEN* the script SHALL skip database readiness wait, data import prompt, and SQL session prompt
* *AND* the script SHALL print connection details to stdout
<!-- /DELTA:NEW -->

<!-- DELTA:CHANGED -->
### Scenario: Database readiness via exapump SELECT 1

* *GIVEN* the Exasol container has been started
* *AND* exapump is available (was pre-installed or installed during startup)
* *WHEN* `wait_for_ready` polls for database readiness
* *THEN* the script SHALL run `exapump sql "SELECT 1" --dsn exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0`
* *AND* the script SHALL consider the database ready when `exapump sql` exits with status 0
* *AND* the script SHALL print "Database is ready." once the check succeeds
<!-- /DELTA:CHANGED -->
