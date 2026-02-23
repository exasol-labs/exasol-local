#!/usr/bin/env bats

load helpers/bats-support/load
load helpers/bats-assert/load

SCRIPT="$BATS_TEST_DIRNAME/../install.sh"

setup() {
  source "$SCRIPT"
  TTY_INPUT=$(mktemp)
}

teardown() {
  rm -f "$TTY_INPUT"
}

@test "prompt_data_import returns 0 when user declines" {
  echo "n" > "$TTY_INPUT"
  run bash -c "
    source '$SCRIPT'
    prompt_data_import < '$TTY_INPUT'
  "
  assert_success
  refute_output --partial "Schema"
}

@test "prompt_data_import proceeds when user presses Enter (default Y)" {
  echo "" > "$TTY_INPUT"
  run bash -c "
    source '$SCRIPT'
    command() { return 1; }
    export -f command
    prompt_data_import < '$TTY_INPUT'
  "
  assert_success
  assert_output --partial "exapump is not installed"
}

@test "prompt_data_import prints hint when exapump is not installed" {
  echo "y" > "$TTY_INPUT"
  run bash -c "
    source '$SCRIPT'
    command() { return 1; }
    export -f command
    prompt_data_import < '$TTY_INPUT'
  "
  assert_success
  assert_output --partial "exapump is not installed"
  assert_output --partial "curl"
}

@test "prompt_data_import invokes exapump for CSV file" {
  printf "y\ntest_schema\n/data/sales.csv\n" > "$TTY_INPUT"
  run bash -c "
    source '$SCRIPT'
    command() { [[ \"\$*\" == *exapump* ]] && return 0 || builtin command \"\$@\"; }
    exapump() { echo \"EXAPUMP_CALLED: \$*\"; }
    export -f command exapump
    prompt_data_import < '$TTY_INPUT'
  "
  assert_success
  assert_output --partial "EXAPUMP_CALLED"
  assert_output --partial "test_schema.sales"
  assert_output --partial "exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0"
}

@test "prompt_data_import derives table name correctly for Parquet file" {
  printf "y\nmy_schema\n/data/events.parquet\n" > "$TTY_INPUT"
  run bash -c "
    source '$SCRIPT'
    command() { [[ \"\$*\" == *exapump* ]] && return 0 || builtin command \"\$@\"; }
    exapump() { echo \"EXAPUMP_CALLED: \$*\"; }
    export -f command exapump
    prompt_data_import < '$TTY_INPUT'
  "
  assert_success
  assert_output --partial "my_schema.events"
}

@test "prompt_data_import propagates exapump failure" {
  printf "y\ntest_schema\n/data/bad.csv\n" > "$TTY_INPUT"
  run bash -c "
    source '$SCRIPT'
    command() { [[ \"\$*\" == *exapump* ]] && return 0 || builtin command \"\$@\"; }
    exapump() { return 1; }
    export -f command exapump
    prompt_data_import < '$TTY_INPUT'
  "
  assert_failure
}
