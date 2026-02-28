# Feature: Platform Detection

Selects the appropriate Exasol Docker image and default volume path for the host operating system, enabling both Linux and macOS (Apple Silicon/arm64) users to run the installer with the correct image.

## Background

- Platform detection occurs at startup before any Docker operations.
- The `IMAGE` and `DEFAULT_EXA_VOLUME` variables are set once and used for all subsequent Docker operations.
- Platform is determined by the output of `uname`.

## Scenarios

<!-- DELTA:NEW -->
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
<!-- /DELTA:NEW -->
