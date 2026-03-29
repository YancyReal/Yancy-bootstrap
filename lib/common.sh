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

login_webdav_script_path() {
  [[ -n "${BOOTSTRAP_ROOT:-}" ]] || die "缺少 BOOTSTRAP_ROOT，无法定位 login-webdav.sh"
  [[ -f "${BOOTSTRAP_ROOT}/login-webdav.sh" ]] || die "缺少登录脚本: ${BOOTSTRAP_ROOT}/login-webdav.sh"
  printf '%s\n' "${BOOTSTRAP_ROOT}/login-webdav.sh"
}

login_webdav_command() {
  local script_path

  script_path="$(login_webdav_script_path)" || return 1
  printf 'bash %q\n' "${script_path}"
}

log_login_webdav_hint() {
  local command

  command="$(login_webdav_command)" || return 1
  log_info "未设置完整 WebDAV 凭据，可运行 ${command} 进行登录"
}

print_login_webdav_banner() {
  local command

  command="$(login_webdav_command)" || return 1

  echo ""
  echo "========================================"
  echo "✅ 安装完成!"
  echo ""
  echo "请运行以下命令登录坚果云 WebDAV："
  echo "  ${command}"
  echo "========================================"
  echo ""
}
