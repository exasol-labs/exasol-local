# Feature: Data Import via exapump

After the Exasol container is running, gives the user the opportunity to load a CSV or Parquet file into the database and/or start an interactive SQL session via exapump.

## Background

- The Exasol container is running and the database accepts connections on `localhost:8563`.

## Scenarios

<!-- DELTA:NEW -->
### Scenario: Input prompts visually distinguished from informational output

* *GIVEN* the installer is prompting the user for a yes/no decision
* *WHEN* any `[Y/n]` prompt is printed
* *THEN* the script SHALL prefix the prompt with a cyan `?` indicator so the user can immediately distinguish it from log lines and step status output
<!-- /DELTA:NEW -->
