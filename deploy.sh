#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$project_dir"

uv run pywrangler sync

stage=$(mktemp -d)
restore_environments() {
  local exit_code=$?
  trap - EXIT

  for environment in venv .venv .venv-workers; do
    if [[ -e "$stage/$environment" ]]; then
      if [[ -e "$project_dir/$environment" ]]; then
        printf 'Cannot restore %s: destination already exists\n' "$environment" >&2
        exit_code=1
      elif ! mv -- "$stage/$environment" "$project_dir/$environment"; then
        exit_code=1
      fi
    fi
  done

  rmdir "$stage" || exit_code=1
  exit "$exit_code"
}
trap restore_environments EXIT

for environment in venv .venv .venv-workers; do
  if [[ -e "$environment" ]]; then
    mv -- "$environment" "$stage/$environment"
  fi
done

npx wrangler deploy "$@"
