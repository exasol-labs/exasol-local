#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="exasol-local"
IMAGE="exasol/docker-db:latest"
SQL_PORT=8563
STOP_TIMEOUT=120
POLL_INTERVAL=1
READY_TIMEOUT="${READY_TIMEOUT:-120}"
EXAPUMP_AVAILABLE=true

# ── UI: ANSI color codes and icon constants ─────────────────────────────────
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
CYAN=$'\033[0;36m'
RED=$'\033[0;31m'
DIM=$'\033[2m'
RESET=$'\033[0m'
_ICON_OK="${GREEN}✓${RESET}"
_ICON_FAIL="${RED}✗${RESET}"
_ICON_ARROW="${CYAN}›${RESET}"

_SPINNER_CHARS=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
_SPINNER_PID=""

log_step()    { printf "${DIM}%s${RESET}\\n" "$*"; }
log_success() { printf "${_ICON_OK} %s\\n" "$*"; }
log_error()   { printf "${_ICON_FAIL} %s\\n" "$*" >&2; }

start_spinner() {
  local label="$1"
  local i=0
  while true; do
    printf "\r${CYAN}%s${RESET} %s " "${_SPINNER_CHARS[$((i % 8))]}" "$label"
    sleep 0.1
    i=$(( i + 1 ))
  done &
  _SPINNER_PID=$!
}

stop_spinner() {
  if [[ -n "$_SPINNER_PID" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null || true
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
    printf "\r\033[2K"
  fi
}

run_with_spinner() {
  local label="$1"; shift
  local tmpfile
  tmpfile="$(mktemp)"
  start_spinner "$label"
  local rc=0
  "$@" >"$tmpfile" 2>&1 || rc=$?
  stop_spinner
  if [[ $rc -eq 0 ]]; then
    log_success "$label"
  else
    log_error "$label"
    cat "$tmpfile" >&2
  fi
  rm -f "$tmpfile"
  return $rc
}

print_welcome() {
  printf '\n%s%sEXASOL%s\n' "$BOLD" "$GREEN" "$RESET"
  printf '%sStart a Docker container with an Exasol DB%s\n\n' "$DIM" "$RESET"
}

# Sets DOCKER to "docker" if the daemon is reachable without sudo, else "sudo docker".
detect_docker_cmd() {
  if docker info > /dev/null 2>&1; then
    DOCKER="docker"
  else
    DOCKER="sudo docker"
  fi
}

# Returns 0 if the Docker image is already present locally.
check_image_cached() {
  $DOCKER image inspect "$IMAGE" > /dev/null 2>&1
}

# Pulls the Docker image from the registry.
pull_image() {
  # shellcheck disable=SC2086
  run_with_spinner "Pulling $IMAGE" $DOCKER pull "$IMAGE"
}

# Outputs the current state of the named container, or empty string if absent.
check_container_state() {
  $DOCKER inspect --format '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || true
}

# Creates and starts a new detached container.
create_container() {
  # shellcheck disable=SC2086
  run_with_spinner "Creating container $CONTAINER_NAME" \
    $DOCKER run \
    --name "$CONTAINER_NAME" \
    -e COSLWD_ENABLED=1 \
    -p "127.0.0.1:${SQL_PORT}:${SQL_PORT}" \
    --privileged \
    --stop-timeout "$STOP_TIMEOUT" \
    --hostname n11 \
    --detach \
    "$IMAGE"
}

# Starts an existing stopped container.
start_existing() {
  # shellcheck disable=SC2086
  run_with_spinner "Starting container $CONTAINER_NAME" \
    $DOCKER start "$CONTAINER_NAME"
}

# Runs 'SELECT 1' via exapump until the database accepts connections, or timeout.
wait_for_ready() {
  local elapsed=0
  local frame=0
  while ! exapump sql "SELECT 1" \
      --dsn 'exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0' \
      >/dev/null 2>&1; do
    if (( elapsed >= READY_TIMEOUT )); then
      printf '\r\033[2K'
      log_error "Database startup timed out after ${READY_TIMEOUT}s"
      return 1
    fi
    printf '\r%s%s%s Waiting for database … %ds ' \
      "$CYAN" "${_SPINNER_CHARS[$((frame % 8))]}" "$RESET" "$elapsed"
    sleep "$POLL_INTERVAL"
    elapsed=$(( elapsed + 1 ))
    frame=$(( frame + 1 ))
  done
  printf '\r\033[2K'
  log_success "Database is ready"
}

# Prints DSN, username, and password to stdout.
print_connection_info() {
  printf '\n%sConnection details:%s\n' "$BOLD" "$RESET"
  printf '%sDSN:%s      localhost:%s\n' "$DIM" "$RESET" "$SQL_PORT"
  printf '%sUsername:%s sys\n' "$DIM" "$RESET"
  printf '%sPassword:%s exasol\n' "$DIM" "$RESET"
}

# Checks whether exapump is available; prompts to install it if not.
# Sets EXAPUMP_AVAILABLE=false if the user declines installation.
ensure_exapump() {
  if command -v exapump > /dev/null 2>&1; then
    return 0
  fi
  printf '%s!%s We could not detect exapump on your system.\n' "$RED" "$RESET"
  printf '%s!%s exapump is a CLI for Exasol data exchange — import, export, and SQL in one command.\n' "$RED" "$RESET"
  printf '%s!%s For more information see: https://github.com/exasol-labs/exapump\n ' "$RED" "$RESET"
  printf '%s?%s Do you want to install exapump now? [Y/n] ' "$CYAN" "$RESET"
  local answer
  read -r answer < "${_TTY:-/dev/tty}"
  case "$answer" in
    [nN])
      EXAPUMP_AVAILABLE=false
      return
      ;;
  esac
  run_with_spinner "Installing exapump" \
    sh -c 'curl -fsSL https://raw.githubusercontent.com/exasol-labs/exapump/main/install.sh | sh'
}

# Prompts the user to optionally load a CSV or Parquet file via exapump.
# Reads from stdin; main() redirects from /dev/tty so this works even in curl|sh.
# Skips silently if the user declines.
prompt_data_import() {
  local answer schema file table
  printf '%s?%s Load a CSV or Parquet file into Exasol? [Y/n] ' "$CYAN" "$RESET"
  read -r answer
  case "$answer" in
    [nN]) return 0 ;;
  esac

  printf '%s?%s Provide the schema you want to load data into. If it does not exist, it will be created automatically.\n' "$CYAN" "$RESET"
  printf '%s?%s Schema: ' "$CYAN" "$RESET"
  read -r schema
  printf '%s?%s Path of the file you want to import. CSV or Parquet formats supported. Table name will be inferred from the name of the file.\n' "$CYAN" "$RESET"
  printf '%s?%s File name: ' "$CYAN" "$RESET"
  read -r file
  table="$(basename "$file")"
  table="${table%.*}"

  run_with_spinner "Creating schema ${schema}" \
    exapump sql \
    "CREATE SCHEMA IF NOT EXISTS ${schema}" \
    --dsn 'exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0'

  run_with_spinner "Uploading ${file}" \
    exapump upload "$file" \
    --table "${schema}.${table}" \
    --dsn 'exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0'
}

# Prompts the user to optionally start an interactive SQL session via exapump.
# Reads from stdin; main() redirects from /dev/tty so this works even in curl|sh.
# Skips silently if the user declines.
prompt_sql_session() {
  local answer
  printf '\n%s?%s Start an interactive SQL session? [Y/n] ' "$CYAN" "$RESET"
  read -r answer
  case "$answer" in
    [nN]) return 0 ;;
  esac

  printf '\n'
  exapump interactive \
    --dsn 'exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0'
}

main() {
  print_welcome
  detect_docker_cmd
  ensure_exapump
  if ! check_image_cached; then
    pull_image
  fi

  local state
  state="$(check_container_state)"

  case "$state" in
    running)
      echo "Container $CONTAINER_NAME is already running."
      ;;
    exited)
      start_existing
      [[ "$EXAPUMP_AVAILABLE" == true ]] && wait_for_ready
      ;;
    *)
      create_container
      [[ "$EXAPUMP_AVAILABLE" == true ]] && wait_for_ready
      ;;
  esac

  print_connection_info
  [[ "$EXAPUMP_AVAILABLE" == true ]] && prompt_data_import < "${_TTY:-/dev/tty}"
  [[ "$EXAPUMP_AVAILABLE" == true ]] && prompt_sql_session < "${_TTY:-/dev/tty}"
}

(return 0 2>/dev/null) || main "$@"
