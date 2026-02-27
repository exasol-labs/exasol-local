# Feature: Docker Checks

Verifies Docker is installed and the daemon is accessible before any Docker operations.

## Background

- The installer runs on Linux.
- Docker Engine is a prerequisite.
- The script auto-detects whether `sudo` is required for Docker commands.

## Scenarios

### Scenario: Docker accessible without sudo

* *GIVEN* `docker info` exits 0 without `sudo`
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL use plain `docker` for all Docker commands

### Scenario: Docker requires sudo

* *GIVEN* `docker info` exits non-zero without `sudo`
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL use `sudo docker` for all Docker commands

### Scenario: Docker not installed

* *GIVEN* the `docker` binary is not present in `PATH`
* *WHEN* the installer runs
* *THEN* the script SHALL print a message stating Docker is not installed
* *AND* the script SHALL print the official Docker installation URL `https://docs.docker.com/engine/install/`
* *AND* the script SHALL exit with a non-zero status code without attempting any Docker operations

### Scenario: Docker daemon not running, successfully started

* *GIVEN* the `docker` binary is present in `PATH`
* *AND* `docker info` exits non-zero both with and without `sudo` (daemon not running)
* *WHEN* the installer runs
* *THEN* the script SHALL attempt to start the Docker daemon via `sudo systemctl start docker` (falling back to `sudo service docker start`)
* *AND* upon successful start, the script SHALL continue execution normally

### Scenario: Docker daemon cannot be started

* *GIVEN* the `docker` binary is present in `PATH`
* *AND* `docker info` exits non-zero both with and without `sudo`
* *AND* the attempt to start the daemon via `systemctl`/`service` fails
* *WHEN* the installer runs
* *THEN* the script SHALL print an error message indicating the Docker daemon could not be started
* *AND* the script SHALL exit with a non-zero status code

## Test Coverage

| Scenario | Test type | File |
|---|---|---|
| Docker accessible without sudo | Unit | `tests/start_container.bats` |
| Docker requires sudo | Unit | `tests/start_container.bats` |
| Docker not installed | Unit | `tests/start_container.bats` |
| Docker daemon not running, successfully started | Unit | `tests/start_container.bats` |
| Docker daemon cannot be started | Unit | `tests/start_container.bats` |
