# Plan: add-mac-platform-detection

## Summary

Adds macOS (Darwin/arm64) support to the installer by detecting the host OS at startup and selecting the appropriate Exasol Docker image. Also removes the Admin UI launch from `specs/mission.md`, which was already absent from the code.

## Design

### Goals / Non-Goals

- Goals
    - Detect Darwin vs Linux via `uname` and set `IMAGE` accordingly
    - Use `public.ecr.aws/r1d8t6u3/exasol:2025.2.0-arm64dev.0` on macOS
    - Use `exasol/docker-db:latest` on Linux (unchanged behavior)
    - Update `specs/mission.md` to include macOS in scope and remove Admin UI from Core Capabilities
- Non-Goals
    - macOS-specific Docker daemon handling (sudo detection unchanged)
    - macOS-specific volume paths (`/var/exa` remains the default)
    - Admin UI launch on any platform (already absent from code; mission.md cleanup only)

### Architecture

```
install.sh startup
    │
    ├─ detect_platform()
    │       ├─ uname == Darwin → IMAGE=public.ecr.aws/r1d8t6u3/exasol:2025.2.0-arm64dev.0
    │       └─ otherwise      → IMAGE=exasol/docker-db:latest
    │
    └─ (rest of flow uses $IMAGE unchanged)
```

### Trade-offs

| Decision | Alternatives Considered | Rationale |
|----------|------------------------|-----------|
| `uname` for OS detection | `$OSTYPE`, `uname -s` | `uname` without flags is POSIX-portable and unambiguous |
| Separate `detect_platform` function | Inline `if` at top of script | Testable in isolation via bats with mocked `uname` |

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Platform detection | NEW | `installer/platform-detection/spec.md` |
| Container lifecycle | CHANGED | `installer/container-lifecycle/spec.md` |

## Implementation Tasks

1. Add `detect_platform()` function to `install.sh` that calls `uname` and sets `IMAGE`
2. Call `detect_platform` at the top of `main()`, before `detect_docker_cmd`
3. Remove hardcoded `IMAGE="exasol/docker-db:latest"` at the top of the script (or make it the Linux default inside `detect_platform`)
4. Update `specs/mission.md`:
   - Move macOS from **Out of Scope** to a supported platform
   - Remove Admin UI launch from **Core Capabilities**
   - Update **Constraints** to include macOS (Darwin/arm64)
5. Add unit tests in `tests/start_container.bats` for both platform scenarios (mocked `uname`)

## Dead Code Removal

| Type | Location | Reason |
|------|----------|--------|
| Variable | `install.sh` line 5 — `IMAGE="exasol/docker-db:latest"` | Replaced by `detect_platform()` |

## Verification

### Scenario Coverage

| Scenario | Test Type | Test Location | Test Name |
|----------|-----------|---------------|-----------|
| Linux platform detected | Unit | `tests/start_container.bats` | `platform detection sets Linux image on non-Darwin` |
| macOS (Darwin) platform detected | Unit | `tests/start_container.bats` | `platform detection sets macOS image on Darwin` |
| Container starts from scratch | E2E | `e2etest` | (existing — no change required) |
| Image already cached | Unit | `tests/start_container.bats` | (existing — no change required) |

### Manual Testing

| Feature | Command | Expected Output |
|---------|---------|-----------------|
| Platform detection (macOS) | `uname` returns `Darwin`; run `bash install.sh` on a Mac | Pulls `public.ecr.aws/r1d8t6u3/exasol:2025.2.0-arm64dev.0` |
| Platform detection (Linux) | `uname` returns `Linux`; run `bash install.sh` on Linux | Pulls `exasol/docker-db:latest` |

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Unit tests | `bats tests/start_container.bats` | 0 failures |
| Lint | `shellcheck install.sh` | 0 errors/warnings |
| E2E tests | `make e2e-tests` | 0 failures |
