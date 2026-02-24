# Feature: Data Import via exapump

After the Exasol container is running, gives the user the opportunity to load a CSV or Parquet file into the database and/or start an interactive SQL session via exapump, so they can immediately work with their data without any additional setup steps.

## Background

- The Exasol container is running and the database accepts connections on `localhost:8563`.
- Default credentials are username `sys` and password `exasol`.
- exapump is installed and available on PATH (ensured by `ensure_exapump` at startup).
- exapump's DSN format is `exasol://user:password@host:port`.
- The `upload` command auto-creates the target table if it does not exist.
- The table name is derived from the file's base name with its extension removed (e.g. `sales_data.csv` → `sales_data`).
- The script runs with `set -euo pipefail`; exapump failures propagate as non-zero exits.
- The prompt reads from `/dev/tty` directly so it works when the script is piped (e.g. `curl | sh`).
- The default answer is **Y** (proceed); only `n` or `N` skips the import.

## Scenarios

### Scenario: User declines import

* *GIVEN* the Exasol container is running and the database is ready
* *WHEN* `install.sh` prompts "Load a CSV or Parquet file into Exasol? [Y/n]"
* *AND* the user enters "n" or "N"
* *THEN* the script SHALL NOT prompt for a schema name or file path
* *AND* the script SHALL NOT invoke `exapump`

### Scenario: User accepts import with Enter (default Y)

* *GIVEN* the Exasol container is running and the database is ready
* *WHEN* `install.sh` prompts "Load a CSV or Parquet file into Exasol? [Y/n]"
* *AND* the user presses Enter without typing (empty input)
* *THEN* the script SHALL proceed to the exapump check (Enter = accept)

### Scenario: Successful CSV import

* *GIVEN* the Exasol container is running and the database is ready
* *AND* `exapump` is installed and available on PATH
* *WHEN* the user enters "y", then provides schema `my_schema` and file path `/data/sales.csv`
* *THEN* the script SHALL invoke `exapump upload /data/sales.csv --table my_schema.sales --dsn exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0`
* *AND* the script SHALL print a confirmation message upon successful completion

### Scenario: Successful Parquet import

* *GIVEN* the Exasol container is running and the database is ready
* *AND* `exapump` is installed and available on PATH
* *WHEN* the user enters "y", then provides schema `analytics` and file path `/data/events.parquet`
* *THEN* the script SHALL invoke `exapump upload /data/events.parquet --table analytics.events --dsn exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0`
* *AND* the script SHALL print a confirmation message upon successful completion

### Scenario: User declines SQL session

* *GIVEN* the Exasol container is running and the database is ready
* *WHEN* `install.sh` prompts "Start an interactive SQL session? [Y/n]"
* *AND* the user enters "n" or "N"
* *THEN* the script SHALL NOT invoke `exapump sql`

### Scenario: User accepts SQL session with Enter (default Y)

* *GIVEN* the Exasol container is running and the database is ready
* *WHEN* `install.sh` prompts "Start an interactive SQL session? [Y/n]"
* *AND* the user presses Enter without typing (empty input)
* *THEN* the script SHALL invoke `exapump interactive --dsn exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0`

### Scenario: exapump not available - all prompts skipped

* *GIVEN* the Exasol container is running
* *AND* exapump was not installed and the user declined installation at startup
* *WHEN* `main` reaches the post-container phase
* *THEN* the script SHALL NOT prompt for data import
* *AND* the script SHALL NOT prompt for an interactive SQL session

### Scenario: Import fails

* *GIVEN* the Exasol container is running and the database is ready
* *AND* `exapump` is installed and available on PATH
* *AND* the user has provided schema and file path
* *WHEN* `exapump upload` exits with a non-zero status code
* *THEN* the script SHALL exit with a non-zero status code

## Test Coverage

| Scenario | Test type | File |
|---|---|---|
| User declines import | Unit | `tests/data_import.bats` |
| User accepts import with Enter (default Y) | Unit | `tests/data_import.bats` |
| Successful CSV import | Unit | `tests/data_import.bats` |
| Successful Parquet import | Unit | `tests/data_import.bats` |
| Import fails | Unit | `tests/data_import.bats` |
| User declines SQL session | Unit | `tests/data_import.bats` |
| User accepts SQL session with Enter (default Y) | Unit | `tests/data_import.bats` |
| exapump not available - all prompts skipped | Unit | `tests/start_container.bats` |
| SQL session invokes exapump sql with DSN | Unit | `tests/data_import.bats` |
