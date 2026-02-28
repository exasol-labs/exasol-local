# Plan: add-ecr-login-workaround

## Summary

Adds a silent, best-effort `docker login public.ecr.aws` call on macOS/arm64 immediately after platform detection, working around an AWS ECR quirk that can cause image pulls to fail without prior login. The call is clearly marked as a temporary workaround to be removed once AWS resolves the issue.

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Platform Detection | CHANGED | `installer/platform-detection/spec.md` |

## Implementation Tasks

1. In `install.sh`, inside `detect_platform()` on the macOS/arm64 branch, after setting `IMAGE` and `DEFAULT_EXA_VOLUME`, add the ECR login call with a prominent workaround comment and full output suppression (`>/dev/null 2>&1 || true`).
2. Add two unit tests to `tests/start_container.bats`: one verifying the login is called on Darwin, one verifying it is NOT called on Linux.

## Dead Code Removal

None.

## Verification

### Scenario Coverage

| Scenario | Test Type | Test Location | Test Name |
|----------|-----------|---------------|-----------|
| ECR login workaround runs on macOS/arm64 | Unit | `tests/start_container.bats` | `ecr login workaround is called on Darwin` |
| ECR login workaround skipped on Linux | Unit | `tests/start_container.bats` | `ecr login workaround is not called on Linux` |

### Manual Testing

| Feature | Command | Expected Output |
|---------|---------|-----------------|
| Platform Detection (macOS) | `bash install.sh` on macOS/arm64 | No error from ECR login; installation proceeds normally even if login fails |

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Run unit tests | `bats tests/start_container.bats` | 0 failures |
| Lint | `shellcheck install.sh` | 0 errors/warnings |
