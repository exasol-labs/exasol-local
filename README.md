# Exasol Local

Run a local [Exasol](https://www.exasol.com) database running in seconds — one command, no configuration.

```sh
curl -fsSL https://raw.githubusercontent.com/juergen-albertsen-exasol/exasol-local/main/install.sh | bash
```

## What it does

1. Pulls the official `exasol/docker-db` Docker image (skipped if already cached)
2. Starts a container named `exasol-local` with sensible defaults
3. Waits until the database accepts connections
4. Prints connection details ready to paste into any SQL client
5. Offers to import a CSV or Parquet file directly into Exasol
6. Offers to start an interactive SQL session

The script is **idempotent** — running it again on a machine that already has the container is safe.

## Requirements

- Linux
- [Docker Engine](https://docs.docker.com/engine/install/)
- `sudo` access if Docker is not accessible without it. Is used automatically when required.
- [exapump](https://github.com/exasol-labs/exapump) — installed automatically if not present; powers the DB readiness check, data import, and interactive SQL session

## Connection details

| Field    | Value            |
|----------|------------------|
| DSN      | `localhost:8563` |
| Username | `sys`            |
| Password | `exasol`         |
| Admin UI | https://localhost:8443 |

## Re-running

If the container is already running, the script prints the connection details and exits — no duplicate containers are created. If the container exists but is stopped, it is restarted