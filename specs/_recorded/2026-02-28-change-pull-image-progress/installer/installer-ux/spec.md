# Feature: Installer Terminal UX

Provides clear, structured terminal output during installation so users understand what the installer is doing at every step.

## Background

- All terminal output uses ANSI color codes for visual hierarchy.

## Scenarios

<!-- DELTA:CHANGED -->
### Scenario: Progress spinner shown for long-running steps

* *GIVEN* the installer is running a long-running operation (container create, container start, database readiness wait, or exapump installation)
* *WHEN* the operation is in progress
* *THEN* the script SHALL display an animated braille spinner next to a human-readable step label
* *AND* the script SHALL update the spinner animation in place without scrolling
<!-- /DELTA:CHANGED -->

<!-- DELTA:NEW -->
### Scenario: Image pull displays native Docker layer progress

* *GIVEN* the platform-selected image is not present locally
* *WHEN* `pull_image` is called
* *THEN* the script SHALL invoke `docker pull` with stdout and stderr connected directly to the terminal
* *AND* the script SHALL NOT wrap the pull in `run_with_spinner`
* *AND* Docker SHALL display its native per-layer download progress with percentage and byte counts
<!-- /DELTA:NEW -->
