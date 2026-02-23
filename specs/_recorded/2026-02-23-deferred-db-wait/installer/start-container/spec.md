# Start Exasol Container

<!-- DELTA:CHANGED -->
### Container starts from scratch

  Given Docker is running
  And no container named `exasol-local` exists
  And the `exasol/docker-db:latest` image is not present locally
  When `install.sh` is executed
  Then the script SHALL pull the `exasol/docker-db:latest` image
  And the script SHALL create and start a container named `exasol-local` with `--privileged`, `--detach`, port `8563` and port `8443` exposed on localhost
  And the script SHALL NOT wait for database readiness immediately after container start
  And the script SHALL print the DSN (`localhost:8563`), username (`sys`), and password (`exasol`) to stdout
  And the script SHALL open `https://localhost:8443` via `xdg-open`
<!-- /DELTA -->

<!-- DELTA:CHANGED -->
### Stopped container exists

  Given Docker is running
  And a container named `exasol-local` exists but is in the stopped state
  When `install.sh` is executed
  Then the script SHALL start the existing container with `docker start`
  And the script SHALL NOT invoke `docker run`
  And the script SHALL NOT wait for database readiness immediately after container start
  And the script SHALL print connection details and open the Admin UI via `xdg-open`
<!-- /DELTA -->
