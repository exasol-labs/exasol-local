# Plan: add-docker-preflight-checks

## Summary

Adds two preflight checks to `detect_docker_cmd` in `install.sh`: (1) exits with a clear message and the official install URL if Docker is not found in `PATH`; (2) attempts to start the Docker daemon via `systemctl`/`service` when `docker info` fails for both plain and sudo invocations, exiting with an error if the start attempt fails.

## Design

### Goals / Non-Goals

- Goals
    - Fail fast with a human-readable message when Docker is not installed
    - Automatically recover from a stopped daemon before touching any Docker resources
- Non-Goals
    - Installing Docker automatically (user is directed to official docs)
    - Supporting non-systemd Linux init systems beyond `service` fallback

### Architecture

`detect_docker_cmd` is refactored into two cooperating functions:

```
main()
  └─ detect_docker_cmd()
       ├─ check_docker_installed()   ← NEW: exits if `docker` not in PATH
       ├─ try docker info (no sudo)  → DOCKER=docker
       ├─ try sudo docker info       → DOCKER="sudo docker"
       └─ daemon not running?
            ├─ start_docker_daemon() ← NEW: systemctl/service, exits on failure
            └─ re-detect with/without sudo
```

### Trade-offs

| Decision | Alternatives Considered | Rationale |
|----------|------------------------|-----------|
| `command -v docker` for install check | `which docker`, `type -p docker` | POSIX-compatible, works in all bash environments |
| `systemctl` first, `service` fallback | systemctl only | Broader Linux compatibility without complexity |
| Exit on daemon-start failure | Warn and continue | Failing silently leads to confusing downstream errors |

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Start Exasol Container | CHANGED | `installer/start-container/spec.md` |

## Implementation Tasks

1. Add `check_docker_installed()` to `install.sh` immediately before `detect_docker_cmd`:
   ```bash
   check_docker_installed() {
     if ! command -v docker &> /dev/null; then
       log_error "Docker is not installed."
       printf 'Install Docker from: https://docs.docker.com/engine/install/\n' >&2
       exit 1
     fi
   }
   ```
2. Add `start_docker_daemon()` to `install.sh` immediately before `detect_docker_cmd`:
   ```bash
   start_docker_daemon() {
     sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null
   }
   ```
3. Refactor `detect_docker_cmd()` to:
   - Call `check_docker_installed` first
   - Try `docker info` (no sudo) → `DOCKER=docker`, return
   - Else try `sudo docker info` → `DOCKER="sudo docker"`, return
   - Else call `run_with_spinner "Starting Docker daemon" start_docker_daemon`; on failure log error and exit 1
   - Re-detect with/without sudo after starting; if still inaccessible log error and exit 1
4. Add unit tests (TDD: RED → GREEN) to `tests/start_container.bats`:
   - `detect_docker_cmd exits when docker not installed`
   - `detect_docker_cmd starts daemon when not running`
   - `detect_docker_cmd exits when daemon cannot be started`

## Dead Code Removal

None.

## Verification

### Scenario Coverage

| Scenario | Test Type | Test Location | Test Name |
|----------|-----------|---------------|-----------|
| Docker not installed | Unit | `tests/start_container.bats` | `detect_docker_cmd exits when docker not installed` |
| Docker daemon not running, successfully started | Unit | `tests/start_container.bats` | `detect_docker_cmd starts daemon when not running` |
| Docker daemon cannot be started | Unit | `tests/start_container.bats` | `detect_docker_cmd exits when daemon cannot be started` |
| Docker accessible without sudo | Unit | `tests/start_container.bats` | existing — `docker info succeeds without sudo` |
| Docker requires sudo | Unit | `tests/start_container.bats` | existing — `docker info requires sudo` |

### Manual Testing

| Feature | Command | Expected Output |
|---------|---------|-----------------|
| Docker not installed | Remove docker from PATH then `bash install.sh` | Error message + `https://docs.docker.com/engine/install/` printed; script exits non-zero |
| Daemon not running, starts OK | Stop Docker daemon then `bash install.sh` | A "Starting Docker daemon" spinner appears; script continues to pull image |
| Daemon cannot start | Stop daemon and block systemctl/service then `bash install.sh` | Error message "Docker daemon could not be started"; script exits non-zero |

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Unit tests | `make test` | 0 failures |
| Lint | `make lint` | 0 errors/warnings |
