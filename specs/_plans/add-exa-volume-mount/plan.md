# Plan: add-exa-volume-mount

## Summary

Adds a `prompt_volume` step during new container creation that asks the user for a local folder to bind-mount at `/exa` inside the Docker container, making database data and configuration persistent across container removals. If the user presses Enter with no input the mount is skipped entirely.

## Design

### Goals / Non-Goals

- Goals
    - Allow users to persist Exasol data across container removals by mounting a local folder at `/exa`
    - Present the prompt only when a new container is being created (not when starting an existing stopped container)
    - Follow the existing `?`-prefixed cyan prompt UX pattern
- Non-Goals
    - Remounting an existing running or stopped container — Docker does not support changing volume mounts on existing containers
    - Multiple volume mounts or custom mount points beyond `/exa`

### Architecture

```
main()
  └─ case *)  ← new container path only
       ├─ prompt_volume          ← NEW: sets EXA_VOLUME global
       └─ create_container       ← CHANGED: uses EXA_VOLUME for -v flag
```

### Trade-offs

| Decision | Alternatives Considered | Rationale |
|----------|------------------------|-----------|
| Ask only on new container | Ask always, ignore for existing | Asking when container exists is confusing — the mount is already fixed at creation time |
| Empty input = no mount | Empty input = use `/var/exa` default | "Leave empty for no mount" is explicit; user must type the path to get a mount |
| Global `EXA_VOLUME` variable | Pass as argument to `create_container` | Consistent with how `EXAPUMP_AVAILABLE` and `DOCKER` are shared across functions |

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Start Exasol Container | CHANGED | `installer/start-container/spec.md` |

## Implementation Tasks

1. Add `EXA_VOLUME=""` initialisation at the top of `install.sh` (alongside other globals)
2. Implement `prompt_volume` function: prints intro text, shows `? Local folder [/var/exa]:` prompt, reads input, sets `EXA_VOLUME`
3. Call `prompt_volume` inside the `*)` case in `main()`, before `create_container`
4. Modify `create_container` to conditionally pass `--volume "${EXA_VOLUME}:/exa"` when `EXA_VOLUME` is non-empty
5. Add unit tests for `prompt_volume` (path provided, empty input) and `create_container` volume flag behaviour

## Dead Code Removal

| Type | Location | Reason |
|------|----------|--------|
| None | — | No existing code is replaced |

## Verification

### Scenario Coverage

| Scenario | Test Type | Test Location | Test Name |
|----------|-----------|---------------|-----------|
| Container starts from scratch (volume flag added) | Unit | `tests/start_container.bats` | `create_container includes --volume flag when EXA_VOLUME is set` |
| Volume path provided | Unit | `tests/start_container.bats` | `prompt_volume sets EXA_VOLUME when user enters a path` |
| Volume mount skipped | Unit | `tests/start_container.bats` | `prompt_volume leaves EXA_VOLUME empty when user presses Enter` |
| Volume prompt presentation | Unit | `tests/start_container.bats` | `prompt_volume prints intro text and cyan prompt` |

### Manual Testing

| Feature | Command | Expected Output |
|---------|---------|-----------------|
| Start Exasol Container (volume mount) | `bash install.sh` on a machine with no existing `exasol-local` container; enter `/tmp/exa-test` at the volume prompt | Container starts; `docker inspect exasol-local` shows `/tmp/exa-test` bound to `/exa` |
| Start Exasol Container (no mount) | `bash install.sh` on a machine with no existing `exasol-local` container; press Enter at the volume prompt | Container starts without any `/exa` bind mount |

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Run unit tests | `bats tests/start_container.bats` | 0 failures |
| Run e2e tests | `make e2e-tests` | Exit 0 |
| Lint | `shellcheck install.sh` | 0 errors/warnings |
