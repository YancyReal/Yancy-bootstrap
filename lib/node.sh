#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${BOOTSTRAP_NODE_LOADED:-}" ]]; then
  return 0
fi
readonly BOOTSTRAP_NODE_LOADED=1

BOOTSTRAP_NVM_DIR="${HOME}/.nvm"
BOOTSTRAP_NODE_VERSION="${BOOTSTRAP_NODE_VERSION:-22}"

load_nvm() {
  export NVM_DIR="${BOOTSTRAP_NVM_DIR}"
  if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
    # shellcheck disable=SC1090
    source "${NVM_DIR}/nvm.sh"
  fi
}

install_nvm() {
  if [[ -s "${BOOTSTRAP_NVM_DIR}/nvm.sh" ]]; then
    return 0
  fi

  log_info "安装 nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
}

install_node_runtime() {
  install_nvm
  load_nvm

  command -v nvm >/dev/null 2>&1 || die "nvm 安装失败"

  log_info "安装 Node.js ${BOOTSTRAP_NODE_VERSION}"
  nvm install "${BOOTSTRAP_NODE_VERSION}"
  nvm alias default "${BOOTSTRAP_NODE_VERSION}"
  nvm use default >/dev/null

  require_command node
  require_command npm
  log_info "Node 版本: $(node -v)"
  log_info "npm 版本: $(npm -v)"
}
