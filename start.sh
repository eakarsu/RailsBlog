#!/usr/bin/env bash

set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$project_dir"

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

runtime_port="${PORT:-3000}"
if [[ ! "$runtime_port" =~ ^[0-9]+$ ]] || [ "$runtime_port" -lt 1 ] || [ "$runtime_port" -gt 65535 ]; then
  printf 'PORT must be an integer between 1 and 65535.\n' >&2
  exit 1
fi
export PORT="$runtime_port"

if [ -n "${RAILS_ENV:-}" ]; then
  runtime_environment="$RAILS_ENV"
elif [ "${NODE_ENV:-}" = test ]; then
  runtime_environment=test
else
  runtime_environment=development
fi
export RAILS_ENV="$runtime_environment"

# Acceptance uses a fresh disposable test database. Normal development and
# production startup retain the explicit pending-migration guard in bin/start.
if [ "$RAILS_ENV" = test ] && [ "${NODE_ENV:-}" = test ]; then
  bundle exec rails db:prepare
  if [ -n "${ADMIN_EMAIL:-}" ] && [ -n "${ADMIN_PASSWORD:-}" ]; then
    BOOTSTRAP_ADMIN_EMAIL="$ADMIN_EMAIL" \
      BOOTSTRAP_ADMIN_PASSWORD="$ADMIN_PASSWORD" \
      bundle exec rails db:seed
  fi
fi

exec ./bin/start
