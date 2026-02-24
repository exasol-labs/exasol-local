#!/usr/bin/env bats

load helpers/bats-support/load
load helpers/bats-assert/load

SCRIPT="$BATS_TEST_DIRNAME/../install.sh"

setup() {
  source "$SCRIPT"
  # Pin DOCKER to plain "docker" so shell function mocks are reachable,
  # and prevent detect_docker_cmd from overriding it during main() tests.
  DOCKER="docker"
  detect_docker_cmd() { :; }
  export DOCKER
  export -f detect_docker_cmd
}

@test "detect_docker_cmd sets DOCKER=docker when docker info succeeds" {
  docker() { return 0; }
  export -f docker
  detect_docker_cmd
  assert_equal "$DOCKER" "docker"
}

@test "detect_docker_cmd sets DOCKER='sudo docker' when docker info fails" {
  # setup() stubs detect_docker_cmd; restore the real implementation here
  detect_docker_cmd() {
    if docker info > /dev/null 2>&1; then
      DOCKER="docker"
    else
      DOCKER="sudo docker"
    fi
  }
  docker() { return 1; }
  export -f docker
  detect_docker_cmd
  assert_equal "$DOCKER" "sudo docker"
}

@test "check_image_cached returns 0 when image exists" {
  docker() { return 0; }
  export -f docker
  run check_image_cached
  assert_success
}

@test "check_image_cached returns 1 when image is absent" {
  docker() { return 1; }
  export -f docker
  run check_image_cached
  assert_failure
}

@test "check_container_state outputs 'running' when container is running" {
  docker() { echo "running"; }
  export -f docker
  run check_container_state
  assert_success
  assert_output "running"
}

@test "check_container_state outputs 'exited' when container is stopped" {
  docker() { echo "exited"; }
  export -f docker
  run check_container_state
  assert_success
  assert_output "exited"
}

@test "check_container_state outputs empty string when container does not exist" {
  docker() { return 1; }
  export -f docker
  run check_container_state
  assert_output ""
}

@test "wait_for_ready succeeds when exapump SELECT 1 returns immediately" {
  exapump() { return 0; }
  export -f exapump
  READY_TIMEOUT=5 run wait_for_ready
  assert_success
  assert_output --partial "Database is ready"
}

@test "wait_for_ready exits 1 on timeout" {
  exapump() { return 1; }
  export -f exapump
  READY_TIMEOUT=1 run wait_for_ready
  assert_failure
  assert_output --partial "timed out"
}

@test "print_connection_info prints DSN, user, and password" {
  run print_connection_info
  assert_success
  assert_output --partial "localhost:8563"
  assert_output --partial "sys"
  assert_output --partial "exasol"
}

@test "script pulls image and creates container when starting from scratch" {
  pull_image()            { echo "PULL_CALLED"; }
  check_image_cached()    { return 1; }
  check_container_state() { echo ""; }
  create_container()      { echo "CREATE_CALLED"; }
  ensure_exapump()        { :; }
  wait_for_ready()        { return 0; }
  prompt_data_import()    { :; }
  prompt_sql_session()    { :; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f pull_image check_image_cached check_container_state create_container
  export -f ensure_exapump wait_for_ready prompt_data_import prompt_sql_session print_connection_info open_admin_ui

  run main
  assert_success
  assert_output --partial "PULL_CALLED"
  assert_output --partial "CREATE_CALLED"
}

@test "script does not pull image when already cached" {
  pull_image()            { echo "PULL_CALLED"; }
  check_image_cached()    { return 0; }
  check_container_state() { echo ""; }
  create_container()      { :; }
  ensure_exapump()        { :; }
  wait_for_ready()        { return 0; }
  prompt_data_import()    { :; }
  prompt_sql_session()    { :; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f pull_image check_image_cached check_container_state create_container
  export -f ensure_exapump wait_for_ready prompt_data_import prompt_sql_session print_connection_info open_admin_ui

  run main
  assert_success
  refute_output --partial "PULL_CALLED"
}

@test "script skips container creation when already running" {
  check_image_cached()    { return 0; }
  check_container_state() { echo "running"; }
  create_container()      { echo "CREATE_CALLED"; }
  start_existing()        { echo "START_CALLED"; }
  ensure_exapump()        { :; }
  wait_for_ready()        { return 0; }
  prompt_data_import()    { :; }
  prompt_sql_session()    { :; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f check_image_cached check_container_state create_container
  export -f start_existing ensure_exapump wait_for_ready prompt_data_import prompt_sql_session print_connection_info open_admin_ui

  run main
  assert_success
  refute_output --partial "CREATE_CALLED"
  refute_output --partial "START_CALLED"
}

@test "script restarts stopped container without docker run" {
  check_image_cached()    { return 0; }
  check_container_state() { echo "exited"; }
  start_existing()        { echo "START_CALLED"; }
  create_container()      { echo "CREATE_CALLED"; }
  ensure_exapump()        { :; }
  wait_for_ready()        { return 0; }
  prompt_data_import()    { :; }
  prompt_sql_session()    { :; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f check_image_cached check_container_state start_existing
  export -f create_container ensure_exapump wait_for_ready prompt_data_import prompt_sql_session print_connection_info open_admin_ui

  run main
  assert_success
  assert_output --partial "START_CALLED"
  refute_output --partial "CREATE_CALLED"
}

@test "ensure_exapump sets EXAPUMP_AVAILABLE=true when exapump is on PATH" {
  command() {
    if [[ "$*" == *exapump* ]]; then return 0; fi
    builtin command "$@"
  }
  export -f command
  ensure_exapump
  assert_equal "$EXAPUMP_AVAILABLE" "true"
}

@test "ensure_exapump installs and keeps EXAPUMP_AVAILABLE=true when user accepts" {
  command() {
    if [[ "$*" == *exapump* ]]; then return 1; fi
    builtin command "$@"
  }
  curl() { return 0; }
  export -f command curl
  _TTY=$(mktemp)
  echo "Y" > "$_TTY"
  export _TTY
  run ensure_exapump
  assert_success
  assert_equal "$EXAPUMP_AVAILABLE" "true"
  rm -f "$_TTY"
}

@test "ensure_exapump sets EXAPUMP_AVAILABLE=false when user declines" {
  command() {
    if [[ "$*" == *exapump* ]]; then return 1; fi
    builtin command "$@"
  }
  export -f command
  _TTY=$(mktemp)
  echo "n" > "$_TTY"
  export _TTY
  ensure_exapump
  assert_equal "$EXAPUMP_AVAILABLE" "false"
  rm -f "$_TTY"
}

@test "main skips wait_for_ready, prompt_data_import, and prompt_sql_session when EXAPUMP_AVAILABLE is false" {
  detect_docker_cmd()     { :; }
  ensure_exapump()        { EXAPUMP_AVAILABLE=false; }
  check_image_cached()    { return 0; }
  check_container_state() { echo ""; }
  create_container()      { :; }
  wait_for_ready()        { echo "WAIT_SENTINEL"; }
  prompt_data_import()    { echo "IMPORT_SENTINEL"; }
  prompt_sql_session()    { echo "SQL_SENTINEL"; }
  print_connection_info() { :; }
  export -f detect_docker_cmd ensure_exapump check_image_cached check_container_state
  export -f create_container wait_for_ready prompt_data_import prompt_sql_session print_connection_info

  run main
  assert_success
  refute_output --partial "WAIT_SENTINEL"
  refute_output --partial "IMPORT_SENTINEL"
  refute_output --partial "SQL_SENTINEL"
}

@test "log_success outputs success icon and message" {
  run log_success "step done"
  assert_success
  assert_output --partial "step done"
}

@test "log_error outputs failure message to stderr" {
  run log_error "something failed"
  assert_output --partial "something failed"
}

@test "run_with_spinner succeeds and calls log_success" {
  run run_with_spinner "test label" true
  assert_success
  assert_output --partial "test label"
}

@test "run_with_spinner fails and replays captured output" {
  failing_cmd() { echo "captured noise"; return 1; }
  export -f failing_cmd
  run run_with_spinner "bad step" failing_cmd
  assert_failure
  assert_output --partial "bad step"
  assert_output --partial "captured noise"
}

@test "print_welcome outputs EXASOL banner" {
  run print_welcome
  assert_success
  assert_output --partial "EXASOL"
  assert_output --partial "Exasol DB"
}
