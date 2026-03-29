#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${BOOTSTRAP_OS_LOADED:-}" ]]; then
  return 0
fi
readonly BOOTSTRAP_OS_LOADED=1

BOOTSTRAP_OS=""
BOOTSTRAP_DISTRO=""
BOOTSTRAP_PACKAGE_MANAGER=""

detect_os() {
  case "$(uname -s)" in
    Darwin)
      BOOTSTRAP_OS="macos"
      BOOTSTRAP_DISTRO="macos"
      BOOTSTRAP_PACKAGE_MANAGER="brew"
      ;;
    Linux)
      BOOTSTRAP_OS="linux"
      if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        case "${ID:-}" in
          ubuntu)
            BOOTSTRAP_DISTRO="ubuntu"
            BOOTSTRAP_PACKAGE_MANAGER="apt"
            ;;
          *)
            die "当前仅支持 Ubuntu Linux，检测到: ${ID:-unknown}"
            ;;
        esac
      else
        die "无法识别 Linux 发行版，缺少 /etc/os-release"
      fi
      ;;
    *)
      die "当前仅支持 macOS 和 Ubuntu，检测到: $(uname -s)"
      ;;
  esac
}

ensure_prerequisites() {
  require_command uname
  require_command mkdir
}

print_os_summary() {
  log_info "操作系统: ${BOOTSTRAP_OS}"
  log_info "发行版: ${BOOTSTRAP_DISTRO}"
  log_info "包管理器: ${BOOTSTRAP_PACKAGE_MANAGER}"
}
