# Feature: Data Import via exapump

After the Exasol container is running, gives the user the opportunity to load a CSV or Parquet file into the database and/or start an interactive SQL session via exapump.

## Background

- The Exasol container is running and the database accepts connections on `localhost:8563`.

## Scenarios

<!-- DELTA:REMOVED -->
### Scenario: exapump not installed

* *GIVEN* the Exasol container is running and the database is ready
* *AND* `exapump` is not found on the system PATH
* *WHEN* the user enters "y" or "Y" at the import prompt
* *THEN* the script SHALL print that exapump is not installed and output the installation command `curl -fsSL https://raw.githubusercontent.com/exasol-labs/exapump/main/install.sh | sh`
* *AND* the script SHALL NOT invoke `exapump`
* *AND* the script SHALL exit with status 0
<!-- /DELTA:REMOVED -->

<!-- DELTA:REMOVED -->
### Scenario: exapump not installed (SQL session)

* *GIVEN* the Exasol container is running and the database is ready
* *AND* `exapump` is not found on the system PATH
* *WHEN* the user enters "y" or "Y" at the SQL session prompt
* *THEN* the script SHALL print that exapump is not installed and output the installation command
* *AND* the script SHALL exit with status 0
<!-- /DELTA:REMOVED -->

<!-- DELTA:NEW -->
### Scenario: exapump not available - all prompts skipped

* *GIVEN* the Exasol container is running
* *AND* exapump was not installed and the user declined installation at startup
* *WHEN* `main` reaches the post-container phase
* *THEN* the script SHALL NOT prompt for data import
* *AND* the script SHALL NOT prompt for an interactive SQL session
<!-- /DELTA:NEW -->
