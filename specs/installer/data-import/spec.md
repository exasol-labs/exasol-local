# Feature: Data Import via exapump

After the Exasol container is running, gives the user the opportunity to load a CSV or Parquet file into the database using exapump, so they can immediately query their own data without any additional setup steps.

## Background

- The Exasol container is running and the database accepts connections on `localhost:8563`.
- Default credentials are username `sys` and password `exasol`.
- exapump CLI (`exapump`) may or may not be installed on the host machine.
- exapump's DSN format is `exasol://user:password@host:port`.
- The `upload` command auto-creates the target table if it does not exist.
- The table name is derived from the file's base name with its extension removed (e.g. `sales_data.csv` → `sales_data`).
- The script runs with `set -euo pipefail`; exapump failures propagate as non-zero exits.

## Scenarios

### Scenario: User declines import

* *GIVEN* the Exasol container is running and the database is ready
* *WHEN* `install.sh` prompts "Do you want to load a data file into Exasol? [y/N]"
* *AND* the user enters "n", "N", or presses Enter (empty)
* *THEN* the script SHALL NOT prompt for a schema name or file path
* *AND* the script SHALL NOT invoke `exapump`

### Scenario: exapump not installed

* *GIVEN* the Exasol container is running and the database is ready
* *AND* `exapump` is not found on the system PATH
* *WHEN* the user enters "y" or "Y" at the import prompt
* *THEN* the script SHALL print that exapump is not installed and output the installation command `curl -fsSL https://raw.githubusercontent.com/exasol-labs/exapump/main/install.sh | sh`
* *AND* the script SHALL NOT invoke `exapump`
* *AND* the script SHALL exit with status 0

### Scenario: Successful CSV import

* *GIVEN* the Exasol container is running and the database is ready
* *AND* `exapump` is installed and available on PATH
* *WHEN* the user enters "y", then provides schema `my_schema` and file path `/data/sales.csv`
* *THEN* the script SHALL invoke `exapump upload /data/sales.csv --table my_schema.sales --dsn exasol://sys:exasol@localhost:8563`
* *AND* the script SHALL print a confirmation message upon successful completion

### Scenario: Successful Parquet import

* *GIVEN* the Exasol container is running and the database is ready
* *AND* `exapump` is installed and available on PATH
* *WHEN* the user enters "y", then provides schema `analytics` and file path `/data/events.parquet`
* *THEN* the script SHALL invoke `exapump upload /data/events.parquet --table analytics.events --dsn exasol://sys:exasol@localhost:8563`
* *AND* the script SHALL print a confirmation message upon successful completion

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
| exapump not installed | Unit | `tests/data_import.bats` |
| Successful CSV import | Unit | `tests/data_import.bats` |
| Successful Parquet import | Unit | `tests/data_import.bats` |
| Import fails | Unit | `tests/data_import.bats` |
