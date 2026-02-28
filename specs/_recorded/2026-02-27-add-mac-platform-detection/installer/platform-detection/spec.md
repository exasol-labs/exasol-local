# Feature: Platform Detection

Selects the appropriate Exasol Docker image for the host operating system, enabling both Linux and macOS (Apple Silicon/arm64) users to run the installer with the correct image.

## Background

- Platform detection occurs at startup before any Docker operations.
- The `IMAGE` variable is set once and used for all subsequent Docker operations.
- Platform is determined by the output of `uname`.

## Scenarios

### Scenario: Linux platform detected

* *GIVEN* the installer is running on a Linux host
* *AND* `uname` returns a kernel name that is NOT `Darwin`
* *WHEN* the installer starts
* *THEN* the script SHALL set `IMAGE` to `exasol/docker-db:latest`

### Scenario: macOS (Darwin) platform detected

* *GIVEN* the installer is running on a macOS host
* *AND* `uname` returns `Darwin`
* *WHEN* the installer starts
* *THEN* the script SHALL set `IMAGE` to `public.ecr.aws/r1d8t6u3/exasol:2025.2.0-arm64dev.0`
