<div align="center">
<picture>
  <source srcset="static/Exasol_Logo_2025_Bright.svg" media="(prefers-color-scheme: dark)">
  <img src="static/Exasol_Logo_2025_Dark.svg" alt="Exasol Logo" width="300">
</picture>
<h1>Local</h1>
<p>Run a local <a href=="https://www.exasol.com">Exasol</a> database in seconds — one command, no configuration.</>
</div>

<p align="center">
  <a href="https://github.com/exasol-labs/exasol-local/stargazers"><img src="https://img.shields.io/github/stars/exasol-labs/exasol-local.svg" alt="GitHub Stars" /></a>
  <a href="https://github.com/exasol-labs/exasol-local/issues"><img src="https://img.shields.io/github/issues/exasol-labs/exasol-local.svg" alt="GitHub Issues" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License" /></a>
</p>

<br clear="all">


## 🚀 Quick Start

```sh
curl -fsSL https://raw.githubusercontent.com/exasol-labs/exasol-local/main/install.sh | bash
```

## ⚙️ What it does

1. Pulls the official `exasol/docker-db` Docker image (skipped if already cached)
2. Starts a container named `exasol-local` with sensible defaults
3. Waits until the database accepts connections
4. Prints connection details ready to paste into any SQL client
5. Offers to import a CSV or Parquet file directly into Exasol
6. Offers to start an interactive SQL session

The script is **idempotent** — running it again on a machine that already has the container is safe.

## 📋 Requirements

- Linux on an x86_64 architecture
- [Docker Engine](https://docs.docker.com/engine/install/)
- `sudo` access if Docker is not accessible without it. Is used automatically when required.
- [exapump](https://github.com/exasol-labs/exapump) — installed automatically if not present; powers the DB readiness check, data import, and interactive SQL session

## 🔌 Connection details

| Field    | Value                  |
|----------|------------------------|
| DSN      | `localhost:8563`       |
| Username | `sys`                  |
| Password | `exasol`               |
| Admin UI | https://localhost:8443 |

## 🔁 Re-running

If the container is already running, the script prints the connection details and exits — no duplicate containers are created. If the container exists but is stopped, it is restarted.
