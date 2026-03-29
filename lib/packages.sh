#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${BOOTSTRAP_PACKAGES_LOADED:-}" ]]; then
  return 0
fi
readonly BOOTSTRAP_PACKAGES_LOADED=1

APT_UPDATED=0

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "当前操作需要 root 权限或 sudo"
  fi
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  log_info "安装 Homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  require_command brew
}

apt_update_once() {
  if [[ "${APT_UPDATED}" -eq 0 ]]; then
    as_root apt-get update
    APT_UPDATED=1
  fi
}

ensure_package_manager() {
  case "${BOOTSTRAP_PACKAGE_MANAGER}" in
    brew)
      ensure_homebrew
      ;;
    apt)
      require_command apt-get
      ;;
    *)
      die "未知包管理器: ${BOOTSTRAP_PACKAGE_MANAGER}"
      ;;
  esac
}

install_packages() {
  local packages=("$@")
  if [[ "${#packages[@]}" -eq 0 ]]; then
    return 0
  fi

  case "${BOOTSTRAP_PACKAGE_MANAGER}" in
    brew)
      brew install "${packages[@]}"
      ;;
    apt)
      apt_update_once
      DEBIAN_FRONTEND=noninteractive as_root apt-get install -y "${packages[@]}"
      ;;
    *)
      die "未知包管理器: ${BOOTSTRAP_PACKAGE_MANAGER}"
      ;;
  esac
}

install_base_packages() {
  ensure_package_manager

  case "${BOOTSTRAP_PACKAGE_MANAGER}" in
    brew)
      install_packages bash curl fd fzf git jq ripgrep unzip zoxide zsh
      ;;
    apt)
      install_packages build-essential ca-certificates curl fd-find file fzf git jq ripgrep tar unzip xz-utils zsh
      ;;
  esac

  ensure_local_bin
}

ensure_local_bin() {
  mkdir -p "${HOME}/.local/bin"
  case ":${PATH}:" in
    *":${HOME}/.local/bin:"*) ;;
    *) export PATH="${HOME}/.local/bin:${PATH}" ;;
  esac
}
