# Plan: change-pull-image-progress

## Summary

Replaces the `run_with_spinner` wrapper in `pull_image` with a direct `docker pull` invocation so Docker's native per-layer progress display (percentage + byte counts) is shown to the user during the image download.

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Installer Terminal UX | CHANGED | `installer/installer-ux/spec.md` |

## Implementation Tasks

1. In `pull_image()`, remove the `run_with_spinner` call and run `$DOCKER pull "$IMAGE"` directly
2. Keep the existing `log_info` lines before the pull so the user has context before docker output starts
3. Add a unit test verifying `pull_image` calls docker directly and does NOT call `run_with_spinner`

## Dead Code Removal

| Type | Location | Reason |
|------|----------|--------|
| `run_with_spinner` call | `install.sh` — `pull_image()` | Replaced by direct `$DOCKER pull` |

## Verification

### Scenario Coverage

| Scenario | Test Type | Test Location | Test Name |
|----------|-----------|---------------|-----------|
| Progress spinner shown for long-running steps | Unit | `tests/start_container.bats` | `progress spinner shown for container create and start steps` (existing — no code change) |
| Image pull displays native Docker layer progress | Unit | `tests/start_container.bats` | `pull_image calls docker pull directly without spinner` |

### Manual Testing

| Feature | Command | Expected Output |
|---------|---------|-----------------|
| Image pull progress | `bash install.sh` on machine without cached image | Docker layer-by-layer progress lines visible in terminal; no spinner |

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Unit tests | `make test` | 0 failures |
| Lint | `make lint` | 0 errors/warnings |
