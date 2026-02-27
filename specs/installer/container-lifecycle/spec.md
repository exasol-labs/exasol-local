# Feature: Container Lifecycle

Manages the Exasol Docker container: pulling the image, creating, starting, and reusing containers.

## Background

- Docker is available (installed and daemon running).
- The container is always named `exasol-local`.
- The Exasol Docker image used is `exasol/docker-db:latest`.
- The database SQL port is `8563` mapped to `localhost:8563`.
- Default credentials are username `sys` and password `exasol`.
- The script is idempotent: running it multiple times MUST NOT create duplicate containers.

## Scenarios

### Scenario: Container starts from scratch

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *AND* the `exasol/docker-db` image is not present locally
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL pull the `exasol/docker-db:latest` image
* *AND* the script SHALL create and start a container named `exasol-local` with `--privileged`, `--stop-timeout 120`, port `8563` exposed on localhost
* *AND* the script SHALL wait until the database is ready
* *AND* the script SHALL print the DSN (`localhost:8563`), username (`sys`), and password (`exasol`) to stdout

### Scenario: Image already cached

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *AND* the `exasol/docker-db:latest` image is already present locally
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL NOT invoke `docker pull`
* *AND* the script SHALL create and start the container
* *AND* the script SHALL print connection details

### Scenario: Container already running

* *GIVEN* Docker is running
* *AND* a container named `exasol-local` is already in the running state
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL NOT start a new container
* *AND* the script SHALL NOT invoke `docker run` or `docker start`
* *AND* the script SHALL print connection details to stdout

### Scenario: Stopped container exists

* *GIVEN* Docker is running
* *AND* a container named `exasol-local` exists but is in the stopped state
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL start the existing container with `docker start exasol-local`
* *AND* the script SHALL NOT invoke `docker run`
* *AND* the script SHALL wait until the database is ready
* *AND* the script SHALL print connection details

## Test Coverage

| Scenario | Test type | File |
|---|---|---|
| Container starts from scratch | E2E | `e2etest` |
| Image already cached | Unit | `tests/start_container.bats` |
| Container already running | Unit + E2E | `tests/start_container.bats`, `e2etest` |
| Stopped container exists | Unit | `tests/start_container.bats` |
| Port 8563 accepts connections after install | E2E | `e2etest` |
