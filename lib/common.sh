#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${BOOTSTRAP_COMMON_LOADED:-}" ]]; then
  return 0
fi
readonly BOOTSTRAP_COMMON_LOADED=1

log_info() {
  printf '[INFO] %s\n' "$*"
}

log_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

log_step() {
  printf '\n==> %s\n' "$*"
}

die() {
  log_error "$*"
  exit 1
}

require_command() {
  local command_name="$1"
  command -v "${command_name}" >/dev/null 2>&1 || die "缺少必要命令: ${command_name}"
}

run_stage() {
  local stage_name="$1"
  shift

  log_step "${stage_name}"
  "$@"
}
