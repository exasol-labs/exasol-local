#!/usr/bin/env bats

load helpers/bats-support/load
load helpers/bats-assert/load

SCRIPT="$BATS_TEST_DIRNAME/../install.sh"

setup() {
  source "$SCRIPT"
}

@test "prompt_data_import returns 0 when user declines" {
  run bash -c '
    source '"$SCRIPT"'
    echo "n" | prompt_data_import
  '
  assert_success
  refute_output --partial "Schema"
}

@test "prompt_data_import prints hint when exapump is not installed" {
  run bash -c '
    source '"$SCRIPT"'
    command() { return 1; }
    export -f command
    echo "y" | prompt_data_import
  '
  assert_success
  assert_output --partial "exapump is not installed"
  assert_output --partial "curl"
}

@test "prompt_data_import invokes exapump for CSV file" {
  run bash -c '
    source '"$SCRIPT"'
    command() { [[ "$*" == *exapump* ]] && return 0 || builtin command "$@"; }
    exapump() { echo "EXAPUMP_CALLED: $*"; }
    export -f command exapump
    printf "y\ntest_schema\n/data/sales.csv\n" | prompt_data_import
  '
  assert_success
  assert_output --partial "EXAPUMP_CALLED"
  assert_output --partial "test_schema.sales"
  assert_output --partial "exasol://sys:exasol@localhost:8563"
}

@test "prompt_data_import derives table name correctly for Parquet file" {
  run bash -c '
    source '"$SCRIPT"'
    command() { [[ "$*" == *exapump* ]] && return 0 || builtin command "$@"; }
    exapump() { echo "EXAPUMP_CALLED: $*"; }
    export -f command exapump
    printf "y\nmy_schema\n/data/events.parquet\n" | prompt_data_import
  '
  assert_success
  assert_output --partial "my_schema.events"
}

@test "prompt_data_import propagates exapump failure" {
  run bash -c '
    source '"$SCRIPT"'
    command() { [[ "$*" == *exapump* ]] && return 0 || builtin command "$@"; }
    exapump() { return 1; }
    export -f command exapump
    printf "y\ntest_schema\n/data/bad.csv\n" | prompt_data_import
  '
  assert_failure
}
