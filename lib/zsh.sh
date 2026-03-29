#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${BOOTSTRAP_ZSH_LOADED:-}" ]]; then
  return 0
fi
readonly BOOTSTRAP_ZSH_LOADED=1

BOOTSTRAP_SKIP_CHSH="${BOOTSTRAP_SKIP_CHSH:-0}"

install_oh_my_zsh() {
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    return 0
  fi

  log_info "安装 oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh_plugin() {
  local repo_url="$1"
  local plugin_name="$2"
  local plugin_dir="${HOME}/.oh-my-zsh/custom/plugins/${plugin_name}"

  if [[ -d "${plugin_dir}" ]]; then
    return 0
  fi

  git clone --depth=1 "${repo_url}" "${plugin_dir}"
}

install_zsh_plugins() {
  install_zsh_plugin \
    "https://github.com/zsh-users/zsh-autosuggestions" \
    "zsh-autosuggestions"
  install_zsh_plugin \
    "https://github.com/zsh-users/zsh-syntax-highlighting" \
    "zsh-syntax-highlighting"
}

install_zshrc() {
  local source_file="${BOOTSTRAP_ROOT}/dotfiles/zshrc"
  local target_file="${HOME}/.zshrc"

  [[ -f "${source_file}" ]] || die "缺少 zsh 配置模板: ${source_file}"

  if [[ -f "${target_file}" ]] && ! cmp -s "${source_file}" "${target_file}"; then
    cp "${target_file}" "${target_file}.bootstrap.bak"
  fi

  cp "${source_file}" "${target_file}"
}

set_default_shell() {
  if [[ "${BOOTSTRAP_SKIP_CHSH}" == "1" ]]; then
    log_info "BOOTSTRAP_SKIP_CHSH=1，跳过默认 shell 切换"
    return 0
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"
  [[ -n "${zsh_path}" ]] || die "zsh 未安装成功"

  if [[ "${SHELL:-}" == "${zsh_path}" ]]; then
    return 0
  fi

  if ! grep -qx "${zsh_path}" /etc/shells 2>/dev/null; then
    log_warn "${zsh_path} 不在 /etc/shells 中，跳过 chsh"
    return 0
  fi

  chsh -s "${zsh_path}" "${USER}"
}

setup_zsh_environment() {
  install_oh_my_zsh
  install_zsh_plugins
  install_zshrc
  set_default_shell
}
