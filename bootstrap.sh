#!/usr/bin/env bash
set -euo pipefail

# 检测必要命令
check_prerequisites() {
  local missing=()
  for cmd in bash curl; do
    command -v "${cmd}" >/dev/null 2>&1 || missing+=("${cmd}")
  done

  if ((${#missing[@]} > 0)); then
    echo "错误: 缺少必要命令: ${missing[*]}"
    echo ""
    echo "Ubuntu/Debian 安装命令:"
    echo "  sudo apt-get update && sudo apt-get install -y bash curl"
    echo ""
    echo "macOS 安装命令:"
    echo "  brew install bash curl"
    exit 1
  fi
}

# 检测并安装 curl（处理 Docker 精简镜像情况）
install_curl_if_needed() {
  if command -v curl >/dev/null 2>&1; then
    return 0
  fi

  echo "==> 安装 curl..."
  install_packages curl
}

# 检测并安装 git
install_git_if_needed() {
  if command -v git >/dev/null 2>&1; then
    return 0
  fi

  echo "==> 安装 git..."
  install_packages git
}

# 自动安装包（支持 apt/homebrew/apk）
install_packages() {
  local pkg="$1"

  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq 2>/dev/null || true
    apt-get install -y --no-install-recommends "${pkg}" 2>/dev/null || true
  elif command -v brew >/dev/null 2>&1; then
    brew install "${pkg}" 2>/dev/null || true
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache "${pkg}" 2>/dev/null || true
  elif command -v yum >/dev/null 2>&1; then
    yum install -y "${pkg}" 2>/dev/null || true
  fi
}

# 获取 GitHub 归档地址
get_archive_url() {
  local repo="${BOOTSTRAP_GITHUB_REPO:-YancyReal/Yancy-bootstrap}"
  local ref="${BOOTSTRAP_GITHUB_REF:-main}"
  echo "https://codeload.github.com/${repo}/tar.gz/refs/heads/${ref}"
}

# 一键安装入口
main() {
  check_prerequisites
  install_curl_if_needed
  install_git_if_needed

  local archive_url
  archive_url="$(get_archive_url)"
  local install_dir="${BOOTSTRAP_INSTALL_DIR:-${HOME}/.local/share/devbox-bootstrap}"
  local temp_dir

  echo "==> 下载 devbox-bootstrap..."
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "${temp_dir}"' EXIT

  curl -fsSL "${archive_url}" -o "${temp_dir}/bootstrap.tar.gz"

  echo "==> 解压安装..."
  tar -xzf "${temp_dir}/bootstrap.tar.gz" -C "${temp_dir}"

  local extracted_dir
  extracted_dir="$(find "${temp_dir}" -maxdepth 1 -mindepth 1 -type d | head -n 1)"
  if [[ -z "${extracted_dir}" ]]; then
    echo "错误: 无法解压归档包" >&2
    exit 1
  fi

  rm -rf "${install_dir}"
  mkdir -p "$(dirname "${install_dir}")"
  mv "${extracted_dir}" "${install_dir}"

  echo "==> 执行安装脚本..."
  local current_dir="${PWD}"
  cd "${install_dir}"
  env "BOOTSTRAP_CALLER_DIR=${current_dir}" exec ./install.sh "$@"
}

main "$@"