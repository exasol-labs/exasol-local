# Feature: Container Lifecycle

Manages the Exasol Docker container: pulling the image, creating, starting, and reusing containers.

## Background

- Docker is available (installed and daemon running).
- The container is always named `exasol-local`.
- The Exasol Docker image is selected by the platform detection step.
- The database SQL port is `8563` mapped to `localhost:8563`.
- Default credentials are username `sys` and password `exasol`.
- The script is idempotent: running it multiple times MUST NOT create duplicate containers.

## Scenarios

<!-- DELTA:CHANGED -->
### Scenario: Container starts from scratch

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *AND* the platform-selected image is not present locally
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL pull the platform-selected image
* *AND* the script SHALL create and start a container named `exasol-local` with `--privileged`, `--stop-timeout 120`, port `8563` exposed on localhost
* *AND* the script SHALL wait until the database is ready
* *AND* the script SHALL print the DSN (`localhost:8563`), username (`sys`), and password (`exasol`) to stdout
<!-- /DELTA:CHANGED -->

<!-- DELTA:CHANGED -->
### Scenario: Image already cached

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *AND* the platform-selected image is already present locally
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL NOT invoke `docker pull`
* *AND* the script SHALL create and start the container
* *AND* the script SHALL print connection details
<!-- /DELTA:CHANGED -->
