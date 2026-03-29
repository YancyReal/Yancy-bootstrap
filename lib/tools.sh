#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${BOOTSTRAP_TOOLS_LOADED:-}" ]]; then
  return 0
fi
readonly BOOTSTRAP_TOOLS_LOADED=1

machine_arch() {
  case "$(uname -m)" in
    x86_64|amd64) printf 'x86_64\n' ;;
    arm64|aarch64) printf 'aarch64\n' ;;
    *) die "不支持的 CPU 架构: $(uname -m)" ;;
  esac
}

github_latest_asset_url() {
  local repo="$1"
  local asset_pattern="$2"

  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | jq -r --arg pattern "${asset_pattern}" '
        .assets[]
        | select(.name | test($pattern))
        | .browser_download_url
      ' \
    | head -n 1
}

download_and_extract() {
  local url="$1"
  local destination="$2"
  local archive_name archive_path

  archive_name="$(basename "${url}")"
  archive_path="${destination}/${archive_name}"

  curl -fsSL "${url}" -o "${archive_path}"

  case "${archive_name}" in
    *.tar.gz)
      tar -xzf "${archive_path}" -C "${destination}"
      ;;
    *.zip)
      unzip -q "${archive_path}" -d "${destination}"
      ;;
    *)
      die "不支持的压缩包格式: ${archive_name}"
      ;;
  esac
}

install_binary_from_release() {
  local repo="$1"
  local asset_pattern="$2"
  shift 2
  local binaries=("$@")
  local url temp_dir binary

  url="$(github_latest_asset_url "${repo}" "${asset_pattern}")"
  [[ -n "${url}" ]] || die "未找到 ${repo} 的匹配发行包: ${asset_pattern}"

  temp_dir="$(mktemp -d)"
  trap "rm -rf $(printf '%q' "${temp_dir}")" RETURN

  download_and_extract "${url}" "${temp_dir}"

  for binary in "${binaries[@]}"; do
    local source_path
    source_path="$(find "${temp_dir}" -type f -name "${binary}" | head -n 1)"
    [[ -n "${source_path}" ]] || die "发行包中缺少二进制: ${binary}"
    install -m 0755 "${source_path}" "${HOME}/.local/bin/${binary}"
  done
}

install_codex() {
  require_command npm
  npm install -g @openai/codex
  require_command codex
}

install_zellij() {
  local arch target_pattern
  arch="$(machine_arch)"

  if [[ "${BOOTSTRAP_OS}" == "macos" ]]; then
    target_pattern="zellij-${arch}-apple-darwin\\.tar\\.gz$"
  else
    target_pattern="zellij-${arch}-unknown-linux-musl\\.tar\\.gz$"
  fi

  install_binary_from_release "zellij-org/zellij" "${target_pattern}" zellij
}

install_yazi() {
  local arch target_pattern
  arch="$(machine_arch)"

  if [[ "${BOOTSTRAP_OS}" == "macos" ]]; then
    target_pattern="yazi-.*${arch}-apple-darwin\\.zip$"
  else
    target_pattern="yazi-.*${arch}-unknown-linux-musl\\.zip$"
  fi

  install_binary_from_release "sxyazi/yazi" "${target_pattern}" yazi ya
}

install_lazygit() {
  local arch os_name target_pattern
  arch="$(machine_arch)"

  case "${arch}" in
    x86_64) arch="x86_64" ;;
    aarch64) arch="arm64" ;;
  esac

  if [[ "${BOOTSTRAP_OS}" == "macos" ]]; then
    os_name="darwin"
  else
    os_name="linux"
  fi

  target_pattern="lazygit_.*_${os_name}_${arch}\\.tar\\.gz$"
  install_binary_from_release "jesseduffield/lazygit" "${target_pattern}" lazygit
}

install_terminal_tools() {
  install_zellij
  install_yazi
  install_lazygit
}
