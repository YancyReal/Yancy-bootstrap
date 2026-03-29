#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${BOOTSTRAP_CC_SWITCH_LOADED:-}" ]]; then
  return 0
fi
readonly BOOTSTRAP_CC_SWITCH_LOADED=1

BOOTSTRAP_WEBDAV_BASE_URL="${BOOTSTRAP_WEBDAV_BASE_URL:-}"
BOOTSTRAP_WEBDAV_USERNAME="${BOOTSTRAP_WEBDAV_USERNAME:-}"
BOOTSTRAP_WEBDAV_PASSWORD="${BOOTSTRAP_WEBDAV_PASSWORD:-}"
BOOTSTRAP_SKIP_CC_SWITCH_SYNC="${BOOTSTRAP_SKIP_CC_SWITCH_SYNC:-0}"

install_cc_switch() {
  if command -v cc-switch >/dev/null 2>&1; then
    log_info "cc-switch 已安装，跳过"
    return 0
  fi

  log_info "安装 cc-switch-cli"
  CC_SWITCH_FORCE=1 CC_SWITCH_INSTALL_DIR="${HOME}/.local/bin" \
    bash -c "$(curl -fsSL https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh)"

  require_command cc-switch
}

prepare_live_configs() {
  mkdir -p "${HOME}/.codex"
  codex --help >/dev/null 2>&1 || true
}

configure_cc_switch_webdav() {
  [[ -n "${BOOTSTRAP_WEBDAV_BASE_URL}" ]] || die "缺少环境变量 BOOTSTRAP_WEBDAV_BASE_URL"
  [[ -n "${BOOTSTRAP_WEBDAV_USERNAME}" ]] || die "缺少环境变量 BOOTSTRAP_WEBDAV_USERNAME"
  [[ -n "${BOOTSTRAP_WEBDAV_PASSWORD}" ]] || die "缺少环境变量 BOOTSTRAP_WEBDAV_PASSWORD"

  cc-switch config webdav set \
    --base-url "${BOOTSTRAP_WEBDAV_BASE_URL}" \
    --username "${BOOTSTRAP_WEBDAV_USERNAME}" \
    --password "${BOOTSTRAP_WEBDAV_PASSWORD}" \
    --enable

  cc-switch config webdav check-connection
}

download_cc_switch_state() {
  cc-switch config webdav download
}

setup_cc_switch() {
  install_cc_switch
  prepare_live_configs

  if [[ "${BOOTSTRAP_SKIP_CC_SWITCH_SYNC}" == "1" ]]; then
    log_info "BOOTSTRAP_SKIP_CC_SWITCH_SYNC=1，跳过 WebDAV 配置与下载"
    return 0
  fi

  # 检查是否有预置的 WebDAV 凭据
  if [[ -n "${BOOTSTRAP_WEBDAV_BASE_URL}" ]] && [[ -n "${BOOTSTRAP_WEBDAV_USERNAME}" ]] && [[ -n "${BOOTSTRAP_WEBDAV_PASSWORD}" ]]; then
    configure_cc_switch_webdav
    download_cc_switch_state
  else
    log_info "未设置完整 WebDAV 凭据，可运行 ./login-webdav.sh 进行登录"
  fi
}
