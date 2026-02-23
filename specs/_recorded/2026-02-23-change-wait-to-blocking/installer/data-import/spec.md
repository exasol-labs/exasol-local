# Feature: Data Import via exapump

After the Exasol container is running, gives the user the opportunity to load a CSV or Parquet file into the database and/or start an interactive SQL session via exapump.

## Background

- Docker is installed and the Docker daemon is running.

## Scenarios

<!-- DELTA:CHANGED -->
### Scenario: Successful CSV import

* *GIVEN* the Exasol container is running and the database is ready
* *AND* `exapump` is installed and available on PATH
* *WHEN* the user enters "y", then provides schema `my_schema` and file path `/data/sales.csv`
* *THEN* the script SHALL invoke `exapump upload /data/sales.csv --table my_schema.sales --dsn exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0`
* *AND* the script SHALL print a confirmation message upon successful completion
<!-- /DELTA:CHANGED -->

<!-- DELTA:CHANGED -->
### Scenario: Successful Parquet import

* *GIVEN* the Exasol container is running and the database is ready
* *AND* `exapump` is installed and available on PATH
* *WHEN* the user enters "y", then provides schema `analytics` and file path `/data/events.parquet`
* *THEN* the script SHALL invoke `exapump upload /data/events.parquet --table analytics.events --dsn exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0`
* *AND* the script SHALL print a confirmation message upon successful completion
<!-- /DELTA:CHANGED -->

<!-- DELTA:CHANGED -->
### Scenario: User accepts SQL session with Enter (default Y)

* *GIVEN* the Exasol container is running and the database is ready
* *WHEN* `install.sh` prompts "Start an interactive SQL session? [Y/n]"
* *AND* the user presses Enter without typing (empty input)
* *THEN* the script SHALL invoke `exapump interactive --dsn exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0`
<!-- /DELTA:CHANGED -->

<!-- DELTA:REMOVED -->
### Scenario: DB wait deferred until user accepts import

* *GIVEN* the container was just started
* *WHEN* the user accepts the import prompt
* *THEN* the script SHALL wait before invoking `exapump`
<!-- /DELTA:REMOVED -->

<!-- DELTA:REMOVED -->
### Scenario: DB wait deferred until user accepts SQL session

* *GIVEN* the container was just started
* *WHEN* the user accepts the SQL session prompt
* *THEN* the script SHALL wait before invoking `exapump interactive`
<!-- /DELTA:REMOVED -->

<!-- DELTA:REMOVED -->
### Scenario: DB wait runs at most once

* *GIVEN* the container was just started
* *WHEN* the user accepts both prompts
* *THEN* the script SHALL call `wait_for_ready` exactly once
<!-- /DELTA:REMOVED -->

<!-- DELTA:REMOVED -->
### Scenario: DB wait skipped when both prompts declined

* *GIVEN* the container was just started
* *WHEN* the user declines both prompts
* *THEN* the script SHALL NOT invoke `wait_for_ready`
<!-- /DELTA:REMOVED -->
