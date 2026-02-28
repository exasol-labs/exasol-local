# Feature: Platform Detection

Selects the appropriate Exasol Docker image and default volume path for the host operating system, enabling both Linux and macOS (Apple Silicon/arm64) users to run the installer with the correct image.

## Background

- Platform detection occurs at startup before any Docker operations.
- The `IMAGE` and `DEFAULT_EXA_VOLUME` variables are set once and used for all subsequent Docker operations.
- Platform is determined by the output of `uname`.

## Scenarios

### Scenario: Linux platform detected

* *GIVEN* the installer is running on a Linux host
* *AND* `uname` returns a kernel name that is NOT `Darwin`
* *WHEN* the installer starts
* *THEN* the script SHALL set `IMAGE` to `exasol/docker-db:latest`
* *AND* the script SHALL set `DEFAULT_EXA_VOLUME` to `/var/exa`

### Scenario: macOS (Darwin) platform detected

* *GIVEN* the installer is running on a macOS host
* *AND* `uname` returns `Darwin`
* *WHEN* the installer starts
* *THEN* the script SHALL set `IMAGE` to `public.ecr.aws/r1d8t6u3/exasol:2025.2.0-arm64dev.0`
* *AND* the script SHALL set `DEFAULT_EXA_VOLUME` to `$HOME/.exasol/exa`

### Scenario: ECR login workaround runs on macOS/arm64

* *GIVEN* the installer is running on a macOS (Darwin/arm64) host
* *WHEN* `detect_platform` completes
* *THEN* the script SHALL attempt `docker login public.ecr.aws`
* *AND* the script SHALL suppress all output from the login attempt, including errors
* *AND* the script SHALL NOT fail or exit if the login attempt fails
* *AND* the workaround code SHALL be clearly commented as a temporary workaround to be removed when the AWS quirk is resolved

### Scenario: ECR login workaround skipped on Linux

* *GIVEN* the installer is running on a Linux (x86_64) host
* *WHEN* `detect_platform` completes
* *THEN* the script SHALL NOT attempt `docker login public.ecr.aws`

## Test Coverage

| Scenario | Test type | File |
|---|---|---|
| Linux platform detected | Unit | `tests/start_container.bats` |
| macOS (Darwin) platform detected | Unit | `tests/start_container.bats` |
| ECR login workaround runs on macOS/arm64 | Unit | `tests/start_container.bats` |
| ECR login workaround skipped on Linux | Unit | `tests/start_container.bats` |
