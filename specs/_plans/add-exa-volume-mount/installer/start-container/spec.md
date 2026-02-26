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
* *AND* the script SHALL prompt the user for a local folder to bind-mount at `/exa` in the container
* *AND* the script SHALL create the folder if it does not already exist
* *AND* the script SHALL create and start a container named `exasol-local` with `--privileged`, `--stop-timeout 120`, port `8563` exposed on localhost, and `--volume <folder>:/exa`
* *AND* the script SHALL wait until the database is ready
* *AND* the script SHALL print the DSN (`localhost:8563`), username (`sys`), and password (`exasol`) to stdout
<!-- /DELTA:CHANGED -->

<!-- DELTA:NEW -->
### Scenario: Volume path provided

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *WHEN* `install.sh` prompts "Local folder [/var/exa]:"
* *AND* the user enters a non-empty path (e.g. `/data/exa`)
* *THEN* the script SHALL set the volume path to the entered value
* *AND* the script SHALL pass `--volume <path>:/exa` to `docker run`
* *AND* the script SHALL create the directory at `<path>` if it does not exist, using `sudo mkdir -p` when Docker requires sudo, otherwise `mkdir -p`

### Scenario: Volume default applied on Enter

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *WHEN* `install.sh` prompts "Local folder [/var/exa]:"
* *AND* the user presses Enter without typing (empty input)
* *THEN* the script SHALL use `/var/exa` as the volume path
* *AND* the script SHALL pass `--volume /var/exa:/exa` to `docker run`
* *AND* the script SHALL create `/var/exa` if it does not exist

### Scenario: Volume prompt presentation

* *GIVEN* the installer is about to create a new container
* *WHEN* the volume prompt is displayed
* *THEN* the script SHALL print dim intro text explaining that the folder is bind-mounted at `/exa` and data persists across restarts and removals
* *AND* the script SHALL display the prompt with a cyan `?` prefix: `? Local folder [/var/exa]:`
<!-- /DELTA:NEW -->
