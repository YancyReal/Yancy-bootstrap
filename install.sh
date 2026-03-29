#!/usr/bin/env bash

set -euo pipefail

BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bootstrap_repo_if_needed() {
  local target_dir archive_url temp_dir extracted_dir

  if [[ -f "${BOOTSTRAP_ROOT}/lib/common.sh" ]]; then
    return 0
  fi

  archive_url="${BOOTSTRAP_ARCHIVE_URL:-https://codeload.github.com/<your-account>/devbox-bootstrap/tar.gz/refs/heads/main}"
  target_dir="${BOOTSTRAP_DIR:-${HOME}/.local/share/devbox-bootstrap}"

  temp_dir="$(mktemp -d)"
  trap 'rm -rf "${temp_dir}"' EXIT

  mkdir -p "${target_dir}"
  curl -fsSL "${archive_url}" -o "${temp_dir}/bootstrap.tar.gz"
  tar -xzf "${temp_dir}/bootstrap.tar.gz" -C "${temp_dir}"

  extracted_dir="$(find "${temp_dir}" -maxdepth 1 -mindepth 1 -type d | head -n 1)"
  [[ -n "${extracted_dir}" ]] || {
    printf '[ERROR] 无法从归档包中定位 bootstrap 目录\n' >&2
    exit 1
  }

  rm -rf "${target_dir}"
  mkdir -p "$(dirname "${target_dir}")"
  mv "${extracted_dir}" "${target_dir}"

  exec "${target_dir}/install.sh" "$@"
}

bootstrap_repo_if_needed "$@"

source "${BOOTSTRAP_ROOT}/lib/common.sh"
source "${BOOTSTRAP_ROOT}/lib/os.sh"
source "${BOOTSTRAP_ROOT}/lib/packages.sh"
source "${BOOTSTRAP_ROOT}/lib/node.sh"
source "${BOOTSTRAP_ROOT}/lib/tools.sh"
source "${BOOTSTRAP_ROOT}/lib/zsh.sh"
source "${BOOTSTRAP_ROOT}/lib/cc_switch.sh"

main() {
  log_step "开始执行开发环境引导"

  detect_os
  ensure_prerequisites

  run_stage "系统识别" print_os_summary
  run_stage "基础依赖安装" install_base_packages
  run_stage "Node.js 与 npm 安装" install_node_runtime
  run_stage "Codex 安装" install_codex
  run_stage "终端工具安装" install_terminal_tools
  run_stage "Zsh 环境安装" setup_zsh_environment
  run_stage "CC-Switch 安装与同步" setup_cc_switch

  # 下载 login-webdav.sh 到当前目录
  log_step "下载 WebDAV 登录脚本"
  local repo="${BOOTSTRAP_GITHUB_REPO:-YancyReal/Yancy-bootstrap}"
  local ref="${BOOTSTRAP_GITHUB_REF:-main}"
  local login_script_url="https://raw.githubusercontent.com/${repo}/${ref}/login-webdav.sh"
  local login_script="${BOOTSTRAP_ROOT}/login-webdav.sh"

  if curl -fsSL "${login_script_url}" -o "${login_script}"; then
    chmod +x "${login_script}"
    log_info "已下载 login-webdav.sh 到当前目录"
  else
    log_warn "下载 login-webdav.sh 失败"
  fi

  echo ""
  echo "========================================"
  echo "✅ 安装完成!"
  echo ""
  echo "请运行以下命令登录坚果云 WebDAV："
  echo "  ./login-webdav.sh"
  echo "========================================"
  echo ""
}

main "$@"
