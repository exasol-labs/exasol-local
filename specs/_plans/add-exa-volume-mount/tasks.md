# Tasks: add-exa-volume-mount

## Phase 2: Implementation

- [x] 2.1 Add `EXA_VOLUME=""` initialisation at the top of `install.sh` (alongside other globals)
- [x] 2.2 Implement `prompt_volume` function: prints intro text, shows `? Local folder [/var/exa]:` prompt, reads input, sets `EXA_VOLUME`
- [x] 2.3 Call `prompt_volume` inside the `*)` case in `main()`, before `create_container`
- [x] 2.4 Modify `create_container` to conditionally pass `--volume "${EXA_VOLUME}:/exa"` when `EXA_VOLUME` is non-empty
- [x] 2.5 Add unit tests for `prompt_volume` (path provided, empty input, prompt presentation) and `create_container` volume flag behaviour

## Phase 3: Verification

- [x] 3.1 Run unit tests: `bats tests/start_container.bats`
- [x] 3.2 Lint: `shellcheck install.sh`
- [x] 3.3 Generate verification report
