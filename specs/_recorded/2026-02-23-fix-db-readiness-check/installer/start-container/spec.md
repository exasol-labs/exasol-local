# Feature: Start Exasol Container

Starts a local Exasol database container and surfaces connection details so a user can immediately connect with any SQL client.

## Background

- Docker is installed and the Docker daemon is running.

## Scenarios

<!-- DELTA:CHANGED -->
### Scenario: Database readiness timeout

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *WHEN* `install.sh` is executed
* *AND* the Admin HTTPS endpoint `https://localhost:8443/` does not respond within 120 seconds
* *THEN* the script SHALL print an error message indicating the startup timed out
* *AND* the script SHALL exit with a non-zero status code
<!-- /DELTA:CHANGED -->

<!-- DELTA:NEW -->
### Scenario: Database readiness via HTTPS admin port

* *GIVEN* the Exasol container has been started
* *WHEN* `wait_for_ready` polls for database readiness
* *THEN* the script SHALL poll `https://localhost:8443/` using `curl -sk --max-time 2`
* *AND* the script SHALL consider the database ready when `curl` exits with status 0
* *AND* the script SHALL NOT use `nc -z` to check TCP port `8563`
* *AND* the script SHALL print "Database is ready." once the check succeeds
<!-- /DELTA:NEW -->
