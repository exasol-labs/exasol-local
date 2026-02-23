# Feature: Start Exasol Container

Starts a local Exasol database container and surfaces connection details so a user can immediately connect with any SQL client.

## Background

- Docker is installed and the Docker daemon is running.

## Scenarios

<!-- DELTA:CHANGED -->
### Scenario: Container starts from scratch

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *AND* the `exasol/docker-db` image is not present locally
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL pull the `exasol/docker-db:latest` image
* *AND* the script SHALL create and start a container named `exasol-local` with `--privileged`, `--stop-timeout 120`, port `8563` and port `8443` exposed on localhost
* *AND* the script SHALL wait until the Admin HTTPS endpoint `https://localhost:8443/` responds
* *AND* the script SHALL print the DSN (`localhost:8563`), username (`sys`), and password (`exasol`) to stdout
* *AND* the script SHALL open `https://localhost:8443` via `xdg-open`
<!-- /DELTA:CHANGED -->

<!-- DELTA:CHANGED -->
### Scenario: Stopped container exists

* *GIVEN* Docker is running
* *AND* a container named `exasol-local` exists but is in the stopped state
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL start the existing container with `docker start exasol-local`
* *AND* the script SHALL NOT invoke `docker run`
* *AND* the script SHALL wait until the Admin HTTPS endpoint `https://localhost:8443/` responds
* *AND* the script SHALL print connection details and open the Admin UI via `xdg-open`
<!-- /DELTA:CHANGED -->
