#!/usr/bin/env bash
set -euo pipefail

# 检测必要命令
check_prerequisites() {
  local missing=()
  for cmd in bash curl git; do
    command -v "${cmd}" >/dev/null 2>&1 || missing+=("${cmd}")
  done

  if ((${#missing[@]} > 0)); then
    echo "错误: 缺少必要命令: ${missing[*]}"
    echo ""
    echo "Ubuntu/Debian 安装命令:"
    echo "  sudo apt-get update && sudo apt-get install -y bash curl git"
    echo ""
    echo "macOS 安装命令:"
    echo "  brew install bash curl git"
    exit 1
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
  cd "${install_dir}"
  exec ./install.sh "$@"
}

main "$@"