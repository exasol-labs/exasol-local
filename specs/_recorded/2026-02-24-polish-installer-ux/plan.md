# Plan: polish-installer-ux

## Summary

Replace the plain-text output of `install.sh` with a polished terminal UX: a welcome banner, colour-coded step logging, animated spinners for long-running operations, suppressed command noise (shown only on failure), and clearly marked input prompts. The improved exapump explanation uses bullet-point copy instead of a single dense line.

## Design

### Goals / Non-Goals

- Goals
    - Print a welcome banner at script entry
    - Show an animated braille spinner for every long-running step (image pull, container start/restart, DB readiness wait, exapump install)
    - Suppress stdout/stderr of docker, curl, and exapump operations; replay to stderr only when the step fails
    - Colour-code step status: cyan spinner → green ✓ on success → red ✗ on failure
    - Replace the exapump install prompt with richer bullet-point copy explaining what each feature enables
    - Visually distinguish all interactive prompts with a cyan `?` prefix
- Non-Goals
    - Respecting `NO_COLOR` or terminal capability detection (always-on ANSI)
    - Changing any functional behaviour (output, exit codes, logic)
    - Supporting Windows or macOS

### Architecture

```
install.sh
│
├─ Color / icon constants
│    BOLD  GREEN  CYAN  RED  DIM  RESET
│    _ICON_OK  _ICON_FAIL  _ICON_ARROW
│
├─ Spinner state
│    _SPINNER_CHARS (array of braille frames)
│    _SPINNER_PID=""
│
├─ UI Helper Functions
│    log_step()          — dim "starting..." line
│    log_success()       — green ✓ line
│    log_error()         — red ✗ line to stderr
│    start_spinner()     — background loop printing animated spinner
│    stop_spinner()      — kill background loop, erase line
│    run_with_spinner()  — wrap a command: spinner → success/fail + replay log
│    print_welcome()     — banner printed once at main() entry
│
└─ Updated Existing Functions
     ensure_exapump()      — richer explanation, run_with_spinner for curl install,
                             "  ? Install exapump now? [Y/n] " prompt format
     pull_image()          — run_with_spinner "Pulling image"
     create_container()    — run_with_spinner "Creating container"
     start_existing()      — run_with_spinner "Starting container"
     wait_for_ready()      — inline spinner with elapsed-time counter
     prompt_data_import()  — "  ? Load a CSV or Parquet file …" prompt format
     prompt_sql_session()  — "  ? Start an interactive SQL session …" prompt format
     print_connection_info()— formatted colour block
     main()                — print_welcome at entry
```

### Design Patterns

| Pattern | Where | Why |
|---------|-------|-----|
| Background subshell spinner | `start_spinner` / `stop_spinner` | Non-blocking animation without external deps |
| Capture-and-replay output | `run_with_spinner` | Hides noise; surfaces errors when they matter |
| Array for braille frames | `_SPINNER_CHARS` | Safe UTF-8 character indexing in bash |
| Color constants via `$'...'` | Module-level globals | shellcheck-safe; no runtime `tput` dependency |
| Inline spinner in polling loop | `wait_for_ready` | Shows elapsed seconds — more informative than generic spinner |

### Trade-offs

| Decision | Alternatives Considered | Rationale |
|----------|------------------------|-----------|
| Always-on ANSI colors | Detect tty / `NO_COLOR` | Simpler code; target audience (dev terminals) always supports color |
| Inline `$'...'` ANSI codes | `tput setaf` | No dependency on terminfo; works in minimal Docker environments |
| `run_with_spinner` captures to tmpfile | Pipe to `/dev/null` | Lets us replay output on failure for actionable error messages |
| Background subshell spinner | External `pv`, `dialog`, etc. | Zero extra dependencies — script is designed to be piped via `curl \| sh` |

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Installer UX — welcome, spinner, step log | NEW | `installer/start-container/spec.md` |
| Installer UX — prompt formatting | NEW | `installer/data-import/spec.md` |

## Implementation Tasks

1. Add ANSI color constants and icon constants at the top of `install.sh` (after globals, before first function)
2. Add `_SPINNER_CHARS` array and `_SPINNER_PID=""` global
3. Add `log_step`, `log_success`, `log_error` functions
4. Add `start_spinner` and `stop_spinner` functions
5. Add `run_with_spinner <label> <cmd…>` function
6. Add `print_welcome` function
7. Update `ensure_exapump`: replace single-line explanation with bullet-point copy (`_ICON_ARROW` per item), format install prompt with `  ${CYAN}?${RESET}` prefix, wrap curl install in `run_with_spinner`
8. Update `pull_image`: replace `echo`+`$DOCKER pull` with `run_with_spinner "Pulling $IMAGE" $DOCKER pull "$IMAGE"`
9. Update `create_container`: replace `echo`+`$DOCKER run` with `run_with_spinner "Creating container $CONTAINER_NAME" $DOCKER run …`
10. Update `start_existing`: replace `echo`+`$DOCKER start` with `run_with_spinner "Starting container $CONTAINER_NAME" $DOCKER start "$CONTAINER_NAME"`
11. Update `wait_for_ready`: replace plain `echo` poll with inline braille spinner showing elapsed seconds; clear line and call `log_success` / `log_error` at end
12. Update `prompt_data_import`: change `printf` prompt line to use `  ${CYAN}?${RESET} Load a CSV or Parquet file into Exasol? [Y/n] ` prefix; wrap exapump commands in `run_with_spinner`
13. Update `prompt_sql_session`: change `printf` prompt line to use `  ${CYAN}?${RESET} Start an interactive SQL session? [Y/n] ` prefix
14. Update `print_connection_info`: use color formatting (bold section header, dim label names)
15. Update `main`: add `print_welcome` call at the top, before `detect_docker_cmd`
16. Update unit tests in `tests/start_container.bats`:
    - Update output assertions that check exact strings produced by changed functions
    - Add tests for `log_success`, `log_error`, `run_with_spinner` (success path, failure path)
    - Add test for `print_welcome`

## Parallelization

| Parallel Group | Tasks |
|----------------|-------|
| Group A — New helpers | 1, 2, 3, 4, 5, 6 |
| Group B — Production updates | 7, 8, 9, 10, 11, 12, 13, 14, 15 |
| Group C — Tests | 16 |

Sequential dependencies:
- Group A → Group B (helpers must exist before existing functions reference them)
- Group B → Group C (tests verify updated functions)

## Dead Code Removal

| Type | Location | Reason |
|------|----------|--------|
| Plain `echo "Pulling …"` | `pull_image` in `install.sh` | Replaced by `run_with_spinner` label |
| Plain `echo "Creating and starting …"` | `create_container` in `install.sh` | Replaced by `run_with_spinner` label |
| Plain `echo "Starting existing …"` | `start_existing` in `install.sh` | Replaced by `run_with_spinner` label |
| Plain `echo "Waiting for database …"` | `wait_for_ready` in `install.sh` | Replaced by inline spinner |
| Plain `echo "Database is ready."` | `wait_for_ready` in `install.sh` | Replaced by `log_success` |

## Verification

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Unit tests | `make test` | 0 failures |
| Lint | `shellcheck install.sh` | 0 errors/warnings |

### Manual Testing

| Feature | Test Steps | Expected Result |
|---------|------------|-----------------|
| Welcome banner | `bash install.sh` (mocked or real) | Bold "exasol-local" header and tagline printed before any other output |
| Spinner during pull | `bash install.sh` on machine without cached image | Braille spinner animates next to "Pulling image …"; replaced by ✓ on success |
| Output suppressed | `bash install.sh` normal run | No raw `docker pull` progress bars or container IDs visible |
| Error replay | Force `docker pull` to fail | Error output from docker shown after ✗ line |
| DB readiness spinner | Normal run | Spinner with elapsed seconds visible during DB startup |
| exapump prompt | Run without exapump on PATH | Bullet-point explanation printed; `?` prefix on install prompt |
| Input prompts | Normal run | All `[Y/n]` prompts prefixed with cyan `?` |
| Connection info | End of successful run | Bold header + dim labels for DSN/Username/Password |

### Scenario Verification

| Scenario | Test Type | Test Location |
|----------|-----------|---------------|
| Welcome banner displayed at startup | Unit | `tests/start_container.bats` |
| Progress spinner for long-running steps | Unit | `tests/start_container.bats` |
| Command output suppressed; displayed on step failure | Unit | `tests/start_container.bats` |
| exapump not installed, user accepts installation | Unit | `tests/start_container.bats` |
| Input prompts visually distinguished | Unit | `tests/start_container.bats` |
