# Plan: add-data-import

## Summary

After the Exasol container is running and ready, prompt the user to optionally load a CSV or Parquet file using exapump. If exapump is not installed, print a hint and skip; otherwise ask for schema name and file path, then run `exapump upload`.

## Design

### Goals / Non-Goals

- Goals
    - Give users a zero-friction path from "container running" to "my data is in Exasol"
    - Support CSV and Parquet files via exapump's auto-detection
    - Gracefully handle missing exapump with an actionable hint
- Non-Goals
    - Installing exapump automatically
    - Supporting multiple files in one session
    - Custom table names (table is derived from filename)
    - Custom credentials (always uses `sys`/`exasol`)

### Architecture

```
install.sh (main)
  └── container running + DB ready
        └── prompt_data_import()
              ├── ask "load a file? [y/N]"
              │     └── no → return
              ├── command -v exapump?
              │     └── no → print hint, return
              ├── read schema name
              ├── read file path
              ├── derive table = basename($file) strip extension
              └── exapump upload "$file" --table "$schema.$table" --dsn "exasol://sys:exasol@localhost:8563"
```

### Design Patterns

| Pattern | Where | Why |
|---------|-------|-----|
| Guard clauses | `prompt_data_import` | Exit early for "no" and "not installed" cases; keeps happy path flat |
| Derive from input | Table name | Avoids extra prompt; filename is usually the right table name |

### Trade-offs

| Decision | Alternatives Considered | Rationale |
|----------|------------------------|-----------|
| Derive table from filename | Ask for table name separately | Reduces prompt count; covers the common case |
| Print hint when exapump missing | Silent skip | Actionable feedback; user opted in so they want to import |
| Let exapump handle file errors | Pre-validate file path | User said so; keeps script simple |

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Data import via exapump | NEW | `installer/data-import/spec.md` |

## Implementation Tasks

1. Add `prompt_data_import()` function to `install.sh`
2. Call `prompt_data_import` from `main()` after the container state case block (after DB is ready)
3. Add unit tests for all five scenarios in `tests/data_import.bats`

## Dead Code Removal

None — this is a new addition only.

## Verification

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Unit tests | `make test` | 0 failures |
| New data import tests | `tests/helpers/bats-core/bin/bats tests/data_import.bats` | 0 failures |
| Lint | `make lint` | 0 shellcheck errors/warnings |

### Manual Testing

| Feature | Test Steps | Expected Result |
|---------|------------|-----------------|
| User declines | Run `bash install.sh` (container already running); enter "n" at prompt | No schema/file prompts; script exits 0 |
| exapump not installed | Temporarily rename `exapump` binary; run script; enter "y" | Prints "exapump is not installed" + install curl command; exits 0 |
| CSV import | Run script; enter "y"; schema `test_schema`; file `sample.csv` | Invokes `exapump upload sample.csv --table test_schema.sample --dsn exasol://sys:exasol@localhost:8563` |
| Parquet import | Same as above with a `.parquet` file | Table name derived correctly, exapump invoked |

### Scenario Verification

| Scenario | Test Type | Test Location |
|----------|-----------|---------------|
| User declines import | Unit | `tests/data_import.bats` |
| exapump not installed | Unit | `tests/data_import.bats` |
| Successful CSV import | Unit | `tests/data_import.bats` |
| Successful Parquet import | Unit | `tests/data_import.bats` |
| Import fails | Unit | `tests/data_import.bats` |
