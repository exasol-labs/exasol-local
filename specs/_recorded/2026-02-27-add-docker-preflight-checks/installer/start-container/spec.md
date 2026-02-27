# Feature: Start Exasol Container

E2E tests run locally via `make e2e-tests` (executes `tests/e2e/install.bats`). They SSH to the remote Linux machine and simulate a real user installation: `curl https://downloads.exasol.com/exasol-local | sh`. Docker operations inside `install.sh` use `sudo docker` when required (auto-detected). The test removes any pre-existing container before running.

## Background

- The installer targets Linux hosts.
- Docker Engine is a prerequisite; the script checks for it before any Docker operation.

## Scenarios

<!-- DELTA:NEW -->
### Scenario: Docker not installed

* *GIVEN* the `docker` binary is not present in `PATH`
* *WHEN* the installer runs
* *THEN* the script SHALL print a message stating Docker is not installed
* *AND* the script SHALL print the official Docker installation URL `https://docs.docker.com/engine/install/`
* *AND* the script SHALL exit with a non-zero status code without attempting any Docker operations
<!-- /DELTA:NEW -->

<!-- DELTA:NEW -->
### Scenario: Docker daemon not running, successfully started

* *GIVEN* the `docker` binary is present in `PATH`
* *AND* `docker info` exits non-zero both with and without `sudo` (daemon not running)
* *WHEN* the installer runs
* *THEN* the script SHALL attempt to start the Docker daemon via `sudo systemctl start docker` (falling back to `sudo service docker start`)
* *AND* upon successful start, the script SHALL continue execution normally
<!-- /DELTA:NEW -->

<!-- DELTA:NEW -->
### Scenario: Docker daemon cannot be started

* *GIVEN* the `docker` binary is present in `PATH`
* *AND* `docker info` exits non-zero both with and without `sudo`
* *AND* the attempt to start the daemon via `systemctl`/`service` fails
* *WHEN* the installer runs
* *THEN* the script SHALL print an error message indicating the Docker daemon could not be started
* *AND* the script SHALL exit with a non-zero status code
<!-- /DELTA:NEW -->
