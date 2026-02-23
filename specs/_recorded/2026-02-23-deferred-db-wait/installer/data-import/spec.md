# Data Import via exapump

<!-- DELTA:CHANGED -->
### Successful CSV import

  Given the Exasol container was just started (database may not yet be ready)
  And `exapump` is installed and available on PATH
  When the user enters "y", then provides schema `myschema` and file path `data.csv`
  Then the script SHALL wait until the database accepts TCP connections on port `8563`
  And the script SHALL invoke `exapump sql "CREATE SCHEMA IF NOT EXISTS myschema" --dsn ...`
  And the script SHALL invoke `exapump upload data.csv --table myschema.data --dsn ...`
  And the script SHALL print a confirmation message upon successful completion
<!-- /DELTA -->

<!-- DELTA:CHANGED -->
### Successful Parquet import

  Given the Exasol container was just started (database may not yet be ready)
  And `exapump` is installed and available on PATH
  When the user enters "y", then provides schema `myschema` and file path `data.parquet`
  Then the script SHALL wait until the database accepts TCP connections on port `8563`
  And the script SHALL invoke `exapump upload data.parquet --table myschema.data --dsn ...`
  And the script SHALL print a confirmation message upon successful completion
<!-- /DELTA -->

<!-- DELTA:CHANGED -->
### User accepts SQL session with Enter (default Y)

  Given the Exasol container was just started (database may not yet be ready)
  When `prompt_sql_session` prompts "Start an interactive SQL session? [Y/n]"
  And the user presses Enter without typing (empty input)
  Then the script SHALL wait until the database accepts TCP connections on port `8563`
  And the script SHALL invoke `exapump interactive --dsn ...`
<!-- /DELTA -->

<!-- DELTA:NEW -->
### DB wait deferred until user accepts import

  Given Docker is running
  And the container was just started (state was `exited` or absent)
  When the script prompts "Load a CSV or Parquet file into Exasol? [Y/n]"
  And the user enters "y" or presses Enter
  Then the script SHALL wait until the database accepts TCP connections on port `8563` before invoking `exapump`
  And the script SHALL NOT have waited before showing the prompt
<!-- /DELTA -->

<!-- DELTA:NEW -->
### DB wait deferred until user accepts SQL session

  Given Docker is running
  And the container was just started (state was `exited` or absent)
  And the user declined the data import prompt
  When the script prompts "Start an interactive SQL session? [Y/n]"
  And the user enters "y" or presses Enter
  Then the script SHALL wait until the database accepts TCP connections on port `8563` before invoking `exapump interactive`
<!-- /DELTA -->

<!-- DELTA:NEW -->
### DB wait runs at most once

  Given Docker is running
  And the container was just started
  When the user accepts both the data import prompt and the SQL session prompt
  Then the script SHALL call `wait_for_ready` exactly once
  And the second prompt's operation SHALL proceed without an additional readiness poll
<!-- /DELTA -->

<!-- DELTA:NEW -->
### DB wait skipped when both prompts declined

  Given Docker is running
  And the container was just started
  When the user enters "n" at both the import prompt and the SQL session prompt
  Then the script SHALL NOT invoke `wait_for_ready` at any point
  And the script SHALL exit without polling port `8563`
<!-- /DELTA -->
