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
  # Default _TTY to /dev/null so tests that do not supply input do not fail
  # when the test runner has no controlling terminal.
  _TTY=/dev/null
  export _TTY
}

@test "detect_docker_cmd sets DOCKER=docker when docker info succeeds" {
  docker() { return 0; }
  export -f docker
  detect_docker_cmd
  assert_equal "$DOCKER" "docker"
}

@test "detect_docker_cmd sets DOCKER='sudo docker' when docker info returns permission denied" {
  source "$SCRIPT"  # restore real detect_docker_cmd
  docker() {
    if [[ "$1" == "info" ]]; then
      echo "Got permission denied while trying to connect to the Docker daemon socket" >&2
      return 1
    fi
  }
  sudo() {
    if [[ "$1" == "docker" && "$2" == "info" ]]; then return 0; fi
    return 1
  }
  export -f docker sudo
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
  prompt_volume()         { :; }
  ensure_exapump()        { :; }
  wait_for_ready()        { return 0; }
  prompt_data_import()    { :; }
  prompt_sql_session()    { :; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f pull_image check_image_cached check_container_state create_container prompt_volume
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
  prompt_volume()         { :; }
  ensure_exapump()        { :; }
  wait_for_ready()        { return 0; }
  prompt_data_import()    { :; }
  prompt_sql_session()    { :; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f pull_image check_image_cached check_container_state create_container prompt_volume
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
  prompt_volume()         { echo "VOLUME_CALLED"; }
  ensure_exapump()        { :; }
  wait_for_ready()        { return 0; }
  prompt_data_import()    { :; }
  prompt_sql_session()    { :; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f check_image_cached check_container_state create_container prompt_volume
  export -f start_existing ensure_exapump wait_for_ready prompt_data_import prompt_sql_session print_connection_info open_admin_ui

  run main
  assert_success
  refute_output --partial "CREATE_CALLED"
  refute_output --partial "START_CALLED"
  refute_output --partial "VOLUME_CALLED"
}

@test "script restarts stopped container without docker run" {
  check_image_cached()    { return 0; }
  check_container_state() { echo "exited"; }
  start_existing()        { echo "START_CALLED"; }
  create_container()      { echo "CREATE_CALLED"; }
  prompt_volume()         { echo "VOLUME_CALLED"; }
  ensure_exapump()        { :; }
  wait_for_ready()        { return 0; }
  prompt_data_import()    { :; }
  prompt_sql_session()    { :; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f check_image_cached check_container_state start_existing prompt_volume
  export -f create_container ensure_exapump wait_for_ready prompt_data_import prompt_sql_session print_connection_info open_admin_ui

  run main
  assert_success
  assert_output --partial "START_CALLED"
  refute_output --partial "CREATE_CALLED"
  refute_output --partial "VOLUME_CALLED"
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
  prompt_volume()         { :; }
  wait_for_ready()        { echo "WAIT_SENTINEL"; }
  prompt_data_import()    { echo "IMPORT_SENTINEL"; }
  prompt_sql_session()    { echo "SQL_SENTINEL"; }
  print_connection_info() { :; }
  export -f detect_docker_cmd ensure_exapump check_image_cached check_container_state prompt_volume
  export -f create_container wait_for_ready prompt_data_import prompt_sql_session print_connection_info

  run main
  assert_success
  refute_output --partial "WAIT_SENTINEL"
  refute_output --partial "IMPORT_SENTINEL"
  refute_output --partial "SQL_SENTINEL"
}

@test "detect_docker_cmd exits when docker not installed" {
  source "$SCRIPT"  # restore real detect_docker_cmd and check_docker_installed
  command() {
    if [[ "$1" == "-v" && "$2" == "docker" ]]; then return 1; fi
    builtin command "$@"
  }
  export -f command
  run detect_docker_cmd
  assert_failure
  assert_output --partial "Docker is not installed."
  assert_output --partial "https://docs.docker.com/engine/install/"
}

@test "detect_docker_cmd exits when docker daemon is not running" {
  source "$SCRIPT"  # restore real detect_docker_cmd
  docker() {
    if [[ "$1" == "info" ]]; then
      echo "Cannot connect to the Docker daemon. Is the docker daemon running?" >&2
      return 1
    fi
  }
  export -f docker
  run detect_docker_cmd
  assert_failure
  assert_output --partial "not running"
}

@test "detect_docker_cmd exits when sudo docker daemon is not running" {
  source "$SCRIPT"  # restore real detect_docker_cmd
  docker() {
    if [[ "$1" == "info" ]]; then
      echo "Got permission denied while trying to connect to the Docker daemon socket" >&2
      return 1
    fi
  }
  sudo() {
    if [[ "$1" == "docker" && "$2" == "info" ]]; then
      echo "Cannot connect to the Docker daemon. Is the docker daemon running?" >&2
      return 1
    fi
    return 1
  }
  export -f docker sudo
  run detect_docker_cmd
  assert_failure
  assert_output --partial "not running"
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

@test "print_welcome lines do not exceed 79 characters" {
  run print_welcome
  assert_success
  stripped="$(printf '%s' "$output" | sed 's/\x1b\[[0-9;]*m//g')"
  while IFS= read -r line; do
    local len="${#line}"
    if (( len > 79 )); then
      fail "Line exceeds 79 characters (${len}): ${line}"
    fi
  done <<< "$stripped"
}

@test "prompt_volume sets EXA_VOLUME when user enters a path" {
  _TTY=$(mktemp)
  echo '/var/exa' > "$_TTY"
  export _TTY
  prompt_volume < "$_TTY"
  assert_equal "$EXA_VOLUME" '/var/exa'
  rm -f "$_TTY"
}

@test "prompt_volume uses default /var/exa when user presses Enter" {
  _TTY=$(mktemp)
  echo '' > "$_TTY"
  export _TTY
  prompt_volume < "$_TTY"
  assert_equal "$EXA_VOLUME" '/var/exa'
  rm -f "$_TTY"
}

@test "prompt_volume prints intro text and cyan prompt" {
  _TTY=$(mktemp)
  echo '' > "$_TTY"
  export _TTY
  run prompt_volume < "$_TTY"
  assert_output --partial 'local folder at /exa'
  assert_output --partial '[/var/exa]'
  rm -f "$_TTY"
}

@test "create_container includes --volume flag when EXA_VOLUME is set" {
  EXA_VOLUME='/var/exa'
  local docker_args_file
  docker_args_file="$(mktemp)"
  export docker_args_file
  docker() { echo "$*" > "$docker_args_file"; }
  mkdir() { :; }
  export -f docker mkdir
  create_container
  run cat "$docker_args_file"
  assert_output --partial '--volume /var/exa:/exa'
  rm -f "$docker_args_file"
}

@test "create_container omits --volume flag when EXA_VOLUME is empty" {
  EXA_VOLUME=''
  local docker_args_file
  docker_args_file="$(mktemp)"
  export docker_args_file
  docker() { echo "$*" > "$docker_args_file"; }
  export -f docker
  create_container
  run cat "$docker_args_file"
  refute_output --partial '--volume'
  rm -f "$docker_args_file"
}
