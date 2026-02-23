#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="exasol-local"
IMAGE="exasol/docker-db:latest"
SQL_PORT=8563
ADMIN_PORT=8443
STOP_TIMEOUT=120
POLL_INTERVAL=1
READY_TIMEOUT="${READY_TIMEOUT:-120}"
_DB_READY=false

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
  echo "Pulling $IMAGE ..."
  $DOCKER pull "$IMAGE"
}

# Outputs the current state of the named container, or empty string if absent.
check_container_state() {
  $DOCKER inspect --format '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || true
}

# Creates and starts a new detached container.
create_container() {
  echo "Creating and starting container $CONTAINER_NAME ..."
  $DOCKER run \
    --name "$CONTAINER_NAME" \
    -e COSLWD_ENABLED=1 \
    -p "127.0.0.1:${SQL_PORT}:${SQL_PORT}" \
    -p "127.0.0.1:${ADMIN_PORT}:${ADMIN_PORT}" \
    --privileged \
    --stop-timeout "$STOP_TIMEOUT" \
    --detach \
    "$IMAGE"
}

# Starts an existing stopped container.
start_existing() {
  echo "Starting existing container $CONTAINER_NAME ..."
  $DOCKER start "$CONTAINER_NAME"
}

# Calls wait_for_ready at most once; subsequent calls are no-ops.
ensure_db_ready() {
  if [[ "$_DB_READY" == "false" ]]; then
    wait_for_ready
    _DB_READY=true
  fi
}

# Polls TCP port $SQL_PORT until the database accepts connections or timeout.
wait_for_ready() {
  local elapsed=0
  echo "Waiting for database on port $SQL_PORT (timeout ${READY_TIMEOUT}s) ..."
  while ! nc -z localhost "$SQL_PORT" 2>/dev/null; do
    if (( elapsed >= READY_TIMEOUT )); then
      echo "ERROR: database startup timed out after ${READY_TIMEOUT}s" >&2
      return 1
    fi
    sleep "$POLL_INTERVAL"
    elapsed=$(( elapsed + 1 ))
  done
  echo "Database is ready."
}

# Prints DSN, username, password, and Admin UI URL to stdout.
print_connection_info() {
  echo ""
  echo "Connection details:"
  echo "  DSN:      localhost:${SQL_PORT}"
  echo "  Username: sys"
  echo "  Password: exasol"
  echo "  Admin UI: https://localhost:${ADMIN_PORT}"
}

# Opens the Admin UI in the default browser (best-effort; silent on failure).
open_admin_ui() {
  xdg-open "https://localhost:${ADMIN_PORT}" > /dev/null 2>&1 || true
}


# Prompts the user to optionally load a CSV or Parquet file via exapump.
# Reads from stdin; main() redirects from /dev/tty so this works even in curl|sh.
# Skips silently if the user declines; prints a hint if exapump is absent.
# Prompts the user to optionally load a CSV or Parquet file via exapump.
# Reads from stdin; main() redirects from /dev/tty so this works even in curl|sh.
# Skips silently if the user declines; prints a hint if exapump is absent.
prompt_data_import() {
  local was_started="${1:-false}"
  local answer schema file table
  printf "Load a CSV or Parquet file into Exasol? [Y/n] "
  read -r answer
  case "$answer" in
    [nN]) return 0 ;;
  esac

  if ! command -v exapump > /dev/null 2>&1; then
    echo "exapump is not installed. To install it, run:"
    echo "  curl -fsSL https://raw.githubusercontent.com/exasol-labs/exapump/main/install.sh | sh"
    return 0
  fi

  printf "Schema name: "
  read -r schema
  printf "File path: "
  read -r file
  table="$(basename "$file")"
  table="${table%.*}"

  if [[ "$was_started" == "true" ]]; then
    ensure_db_ready
  fi

  exapump sql \
    "CREATE SCHEMA IF NOT EXISTS ${schema}" \
    --dsn 'exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0' \
  && \
  exapump upload "$file" \
    --table "${schema}.${table}" \
    --dsn 'exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0'
}

# Prompts the user to optionally start an interactive SQL session via exapump.
# Reads from stdin; main() redirects from /dev/tty so this works even in curl|sh.
# Skips silently if the user declines; prints a hint if exapump is absent.
prompt_sql_session() {
  local was_started="${1:-false}"
  local answer
  printf "Start an interactive SQL session? [Y/n] "
  read -r answer
  case "$answer" in
    [nN]) return 0 ;;
  esac

  if [[ "$was_started" == "true" ]]; then
    ensure_db_ready
  fi

  exapump interactive \
    --dsn 'exasol://sys:exasol@localhost:8563?tls=true&validateservercertificate=0'
}

main() {
  detect_docker_cmd
  if ! check_image_cached; then
    pull_image
  fi

  local state
  state="$(check_container_state)"

  local was_started=false
  case "$state" in
    running)
      echo "Container $CONTAINER_NAME is already running."
      ;;
    exited)
      start_existing
      was_started=true
      ;;
    *)
      create_container
      was_started=true
      ;;
  esac

  prompt_data_import "$was_started" < "${_TTY:-/dev/tty}"
  prompt_sql_session "$was_started" < "${_TTY:-/dev/tty}"
  print_connection_info
  open_admin_ui
}

(return 0 2>/dev/null) || main "$@"
