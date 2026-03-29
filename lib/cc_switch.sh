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
BOOTSTRAP_INTERACTIVE="${BOOTSTRAP_INTERACTIVE:-0}"

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

# 交互式配置 WebDAV
prompt_cc_switch_webdav() {
  echo ""
  echo "==> 配置 cc-switch WebDAV (坚果云)"
  echo ""
  echo "请输入您的坚果云 WebDAV 信息："
  echo "(直接回车使用默认值 https://dav.jianguoyun.com/dav/)"
  echo ""

  read -rp "WebDAV 地址 [$BOOTSTRAP_WEBDAV_BASE_URL]: " input_url
  read -rp "用户名: " input_user
  read -rsp "密码: " input_pass
  echo ""

  BOOTSTRAP_WEBDAV_BASE_URL="${input_url:-${BOOTSTRAP_WEBDAV_BASE_URL}}"
  BOOTSTRAP_WEBDAV_USERNAME="${input_user}"
  BOOTSTRAP_WEBDAV_PASSWORD="${input_pass}"

  if [[ -z "${BOOTSTRAP_WEBDAV_USERNAME}" ]] || [[ -z "${BOOTSTRAP_WEBDAV_PASSWORD}" ]]; then
    echo "错误: 用户名和密码不能为空"
    return 1
  fi
}

setup_cc_switch() {
  install_cc_switch
  prepare_live_configs

  if [[ "${BOOTSTRAP_SKIP_CC_SWITCH_SYNC}" == "1" ]]; then
    log_info "BOOTSTRAP_SKIP_CC_SWITCH_SYNC=1，跳过 WebDAV 配置与下载"
    return 0
  fi

  # 如果未设置 WebDAV 变量或启用了交互模式，则提示用户输入
  if [[ "${BOOTSTRAP_INTERACTIVE}" == "1" ]] || [[ -z "${BOOTSTRAP_WEBDAV_BASE_URL}" ]] || [[ -z "${BOOTSTRAP_WEBDAV_USERNAME}" ]]; then
    if [[ -t 0 ]] || [[ "${BOOTSTRAP_INTERACTIVE}" == "1" ]]; then  # 交互式终端或强制交互模式
      prompt_cc_switch_webdav
    else
      log_info "未设置 WebDAV 凭据且非交互式终端，跳过 WebDAV 配置"
      return 0
    fi
  fi

  configure_cc_switch_webdav
  download_cc_switch_state
}
