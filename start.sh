#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_dir"

load_env_file() {
  local key value
  [ -f "$project_dir/.env" ] || return 0
  while IFS='=' read -r key value; do
    key="${key#export }"
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    [ -z "${!key+x}" ] || continue
    value="${value%$'\r'}"
    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
      value="${value:1:${#value}-2}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
      value="${value:1:${#value}-2}"
    fi
    export "$key=$value"
  done < "$project_dir/.env"
}

load_env_file

if [ -x /opt/homebrew/opt/ruby/bin/ruby ]; then
  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
fi
if ! command -v ruby >/dev/null 2>&1 || ! command -v bundle >/dev/null 2>&1; then
  printf 'Ruby 3.2 or newer and Bundler are required.\n' >&2
  exit 1
fi
if ! ruby -e 'exit((RUBY_VERSION.split(".").first(2).map(&:to_i) <=> [3, 2]) >= 0 ? 0 : 1)'; then
  printf 'Ruby 3.2 or newer is required.\n' >&2
  exit 1
fi
if ! bundle check >/dev/null 2>&1; then
  printf 'Bundle is incomplete; run bundle install before startup.\n' >&2
  exit 1
fi

backend_port="${BACKEND_PORT:-${PORT:-}}"
frontend_port="${FRONTEND_PORT:-}"
for runtime_port in "$backend_port" "$frontend_port"; do
  if [[ ! "$runtime_port" =~ ^[0-9]+$ ]] || [ "$runtime_port" -lt 1 ] || [ "$runtime_port" -gt 65535 ]; then
    printf 'BACKEND_PORT and FRONTEND_PORT must be integers between 1 and 65535.\n' >&2
    exit 1
  fi
  if command -v lsof >/dev/null 2>&1 && lsof -tiTCP:"$runtime_port" -sTCP:LISTEN >/dev/null 2>&1; then
    printf 'Port %s is already in use.\n' "$runtime_port" >&2
    exit 1
  fi
done
if [ "$backend_port" = "$frontend_port" ]; then
  printf 'BACKEND_PORT and FRONTEND_PORT must be distinct.\n' >&2
  exit 1
fi
if [ -z "${OPENROUTER_API_KEY:-}" ] || [ -z "${OPENROUTER_MODEL:-}" ]; then
  printf 'OPENROUTER_API_KEY and OPENROUTER_MODEL are required.\n' >&2
  exit 1
fi
if [ "${OPENROUTER_BASE_URL:-}" != "https://openrouter.ai/api/v1" ]; then
  printf 'OPENROUTER_BASE_URL must be https://openrouter.ai/api/v1.\n' >&2
  exit 1
fi
case "${ALLOW_SCHEMA_MIGRATION:-}" in true|1) ;; *) printf 'ALLOW_SCHEMA_MIGRATION=true is required.\n' >&2; exit 1;; esac

if [ "${NODE_ENV:-development}" = production ]; then
  runtime_environment=production
elif [ "${NODE_ENV:-}" = test ]; then
  runtime_environment=test
else
  runtime_environment=development
fi
export RAILS_ENV="$runtime_environment"
export LOCAL_DEMO_AUTH=true

bundle exec rails db:prepare
bundle exec rails db:seed
mkdir -p "$project_dir/tmp/pids"

api_pid=""
ui_pid=""
cleanup() {
  [ -z "$api_pid" ] || kill "$api_pid" 2>/dev/null || true
  [ -z "$ui_pid" ] || kill "$ui_pid" 2>/dev/null || true
  wait "$api_pid" "$ui_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

PORT="$backend_port" PIDFILE="$project_dir/tmp/pids/runtime-api.pid" ./bin/start &
api_pid=$!
PORT="$frontend_port" PIDFILE="$project_dir/tmp/pids/runtime-ui.pid" ./bin/start &
ui_pid=$!
while kill -0 "$api_pid" 2>/dev/null && kill -0 "$ui_pid" 2>/dev/null; do sleep 1; done
wait "$api_pid" "$ui_pid"
