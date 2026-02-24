# Feature: Start Exasol Container

Starts a local Exasol database container and surfaces connection details so a user can immediately connect with any SQL client.

## Background

- Docker is installed and the Docker daemon is running.
- The container is always named `exasol-local`.
- The Exasol Docker image used is `exasol/docker-db:latest`.
- The database SQL port is `8563` mapped to `localhost:8563`.
- Default credentials are username `sys` and password `exasol`.
- The script is idempotent: running it multiple times MUST NOT create duplicate containers.
- The script auto-detects whether `sudo` is required: if `docker info` succeeds without `sudo`, plain `docker` is used; otherwise `sudo docker` is used.

## Scenarios

### Scenario: Docker accessible without sudo

* *GIVEN* `docker info` exits 0 without `sudo`
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL use plain `docker` for all Docker commands

### Scenario: Docker requires sudo

* *GIVEN* `docker info` exits non-zero without `sudo`
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL use `sudo docker` for all Docker commands

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

### Scenario: Database readiness timeout

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *WHEN* `install.sh` is executed
* *AND* the database does not become ready within 120 seconds
* *THEN* the script SHALL print an error message indicating the startup timed out
* *AND* the script SHALL exit with a non-zero status code

### Scenario: Database readiness via exapump SELECT 1

* *GIVEN* the Exasol container has been started
* *AND* exapump is available (was pre-installed or installed during startup)
* *WHEN* `wait_for_ready` polls for database readiness
* *THEN* the script SHALL run `exapump sql "SELECT 1" --dsn exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0`
* *AND* the script SHALL consider the database ready when `exapump sql` exits with status 0
* *AND* the script SHALL print "Database is ready." once the check succeeds

### Scenario: exapump already installed

* *GIVEN* `exapump` is available on the system PATH
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL NOT prompt the user to install exapump
* *AND* the script SHALL proceed with full functionality (DB readiness wait, data import, SQL session prompts)

### Scenario: exapump not installed, user accepts installation

* *GIVEN* `exapump` is not available on the system PATH
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL display bullet points explaining what exapump enables (database readiness wait, CSV/Parquet import, interactive SQL sessions) and that the installer works without it
* *AND* the script SHALL prompt with a cyan `?` prefix: `? Install exapump now? [Y/n]`
* *AND* when the user confirms, the script SHALL install exapump via curl with a spinner and continue with full functionality

### Scenario: exapump not installed, user declines installation

* *GIVEN* `exapump` is not available on the system PATH
* *WHEN* `install.sh` prompts "Install exapump now? [Y/n]" and the user enters "n" or "N"
* *THEN* the script SHALL skip database readiness wait, data import prompt, and SQL session prompt
* *AND* the script SHALL print connection details to stdout

## Test Coverage

| Scenario | Test type | File |
|---|---|---|
| Docker accessible without sudo | Unit | `tests/start_container.bats` |
| Docker requires sudo | Unit | `tests/start_container.bats` |
| Container starts from scratch | E2E | `e2etest` |
| Image already cached | Unit | `tests/start_container.bats` |
| Container already running | Unit + E2E | `tests/start_container.bats`, `e2etest` |
| Stopped container exists | Unit | `tests/start_container.bats` |
| Database readiness timeout | Unit | `tests/start_container.bats` |
| Database readiness via exapump SELECT 1 | Unit | `tests/start_container.bats` |
| exapump already installed | Unit | `tests/start_container.bats` |
| exapump not installed, user accepts installation | Unit | `tests/start_container.bats` |
| exapump not installed, user declines installation | Unit | `tests/start_container.bats` |
| Port 8563 accepts connections after install | E2E | `e2etest` |

E2E tests run locally via `make e2e-tests` (executes `./e2etest`). They SSH to the remote Linux machine and simulate a real user installation: `curl -fsSL <url> | bash`. Docker operations inside `install.sh` use `sudo` when required (auto-detected). The test removes any pre-existing container before running.
