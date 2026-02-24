# Verification Report: add-exapump-detection

**Generated:** 2026-02-24

## Test Evidence

### Coverage

| Type | Coverage % |
|------|------------|
| Unit | All 5 plan scenarios covered |
| Integration | n/a |

### Test Results

| Type | Run | Passed | Ignored |
|------|-----|--------|---------|
| Unit | 18 | 17 | 1 (pre-existing, unrelated) |
| Integration | 0 | — | — |

### Manual Tests

| Test | Result |
|------|--------|
| exapump already installed — no install prompt, proceeds normally | not run (no live env) |
| exapump absent, accept install — installs, proceeds with wait + prompts | not run |
| exapump absent, decline install — skips DB wait, import, SQL session | not run |

## Tool Evidence

### Linter

```
$ shellcheck install.sh
(no output)
EXIT: 0
```

### Formatter

n/a

## Scenario Coverage

| Domain | Feature | Scenario | Implemented | Tested |
|--------|---------|----------|-------------|--------|
| installer/start-container | ensure_exapump | exapump already installed | ✓ | ✓ |
| installer/start-container | ensure_exapump | exapump not installed, user accepts | ✓ | ✓ |
| installer/start-container | ensure_exapump | exapump not installed, user declines | ✓ | ✓ |
| installer/start-container | main skip behaviour | all prompts skipped when EXAPUMP_AVAILABLE=false | ✓ | ✓ |
| installer/start-container | wait_for_ready | DB readiness via exapump SELECT 1 | ✓ (pre-existing) | ✓ (pre-existing) |

## Notes

- **Pre-existing test failure (test 2):** `detect_docker_cmd sets DOCKER='sudo docker' when docker info fails` — the shell function mock `docker() { return 1; }` does not intercept the real Docker binary on this machine because the local Docker daemon is active. Confirmed pre-existing by running `make test` on the stashed (pre-change) state. Unrelated to this plan's changes.
- **Dead code in tests:** `open_admin_ui()` is mocked in 4 integration tests but doesn't exist in `install.sh`. Pre-existing. Out of scope.
- **`[[ "$EXAPUMP_AVAILABLE" == true ]] && cmd` with `set -e`:** Safe per bash `&&`-list exemption rules — a failing non-final command in a `&&` list does not trigger `set -e`. Confirmed by test 18 passing with `assert_success` when `EXAPUMP_AVAILABLE=false`.
