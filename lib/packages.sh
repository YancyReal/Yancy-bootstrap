#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${BOOTSTRAP_PACKAGES_LOADED:-}" ]]; then
  return 0
fi
readonly BOOTSTRAP_PACKAGES_LOADED=1

APT_UPDATED=0
ALIYUN_UBUNTU_MIRROR="https://mirrors.aliyun.com/ubuntu/"
ALIYUN_UBUNTU_PORTS_MIRROR="https://mirrors.aliyun.com/ubuntu-ports/"

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

contains_ubuntu_source_entries() {
  local source_file="$1"
  extract_ubuntu_source_urls "${source_file}" | grep -q .
}

extract_ubuntu_source_urls() {
  local source_file="$1"

  awk '
    /^(deb|deb-src)[[:space:]]/ {
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^https?:\/\//) {
          print $i
        }
      }
    }
    /^URIs:[[:space:]]/ {
      for (i = 2; i <= NF; i++) {
        print $i
      }
    }
  ' "${source_file}" | grep -E '/ubuntu(-ports)?/?$' || true
}

is_domestic_ubuntu_url() {
  local source_url="$1"

  grep -Eiq \
    '^https?://(mirrors\.tuna\.tsinghua\.edu\.cn|mirrors\.ustc\.edu\.cn|mirrors\.aliyun\.com|repo\.huaweicloud\.com|mirrors\.cloud\.tencent\.com|mirrors\.163\.com|mirrors\.nju\.edu\.cn)/(ubuntu|ubuntu-ports)(/|$)' \
    <<<"${source_url}"
}

uses_domestic_ubuntu_mirror() {
  local source_file="$1"
  local source_url
  local found_url=0

  while IFS= read -r source_url; do
    found_url=1
    is_domestic_ubuntu_url "${source_url}" || return 1
  done < <(extract_ubuntu_source_urls "${source_file}")

  [[ "${found_url}" -eq 1 ]]
}

replace_ubuntu_mirror_in_source_file() {
  local source_file="$1"
  local temp_file

  temp_file="$(mktemp)"
  sed -E \
    -e '/^(deb|deb-src)[[:space:]]/ s#https?://[^[:space:]]+/ubuntu-ports/?([[:space:]]|$)#'"${ALIYUN_UBUNTU_PORTS_MIRROR}"'\1#g' \
    -e '/^(deb|deb-src)[[:space:]]/ s#https?://[^[:space:]]+/ubuntu/?([[:space:]]|$)#'"${ALIYUN_UBUNTU_MIRROR}"'\1#g' \
    -e '/^URIs:/ s#https?://[^[:space:]]+/ubuntu-ports/?([[:space:]]|$)#'"${ALIYUN_UBUNTU_PORTS_MIRROR}"'\1#g' \
    -e '/^URIs:/ s#https?://[^[:space:]]+/ubuntu/?([[:space:]]|$)#'"${ALIYUN_UBUNTU_MIRROR}"'\1#g' \
    "${source_file}" > "${temp_file}"

  if cmp -s "${source_file}" "${temp_file}"; then
    rm -f "${temp_file}"
    die "无法识别 ${source_file} 中的 Ubuntu 官方源格式"
  fi

  as_root cp "${source_file}" "${source_file}.bootstrap.bak"
  as_root install -m 0644 "${temp_file}" "${source_file}"
  rm -f "${temp_file}"
}

ensure_ubuntu_domestic_mirror() {
  local sources_list="/etc/apt/sources.list"
  local deb822_file="/etc/apt/sources.list.d/ubuntu.sources"
  local source_file
  local found_source_file=0

  [[ "${BOOTSTRAP_DISTRO}" == "ubuntu" ]] || return 0

  for source_file in "${sources_list}" "${deb822_file}"; do
    [[ -r "${source_file}" ]] || continue
    contains_ubuntu_source_entries "${source_file}" || continue
    found_source_file=1

    if uses_domestic_ubuntu_mirror "${source_file}"; then
      log_info "检测到 ${source_file} 已使用国内源，跳过切换"
      continue
    fi

    log_info "检测到 ${source_file} 未使用国内源，切换为阿里源"
    replace_ubuntu_mirror_in_source_file "${source_file}"
  done

  [[ "${found_source_file}" -eq 1 ]] || die "未找到 Ubuntu 官方源配置文件"
}

apt_update_once() {
  if [[ "${APT_UPDATED}" -eq 0 ]]; then
    ensure_ubuntu_domestic_mirror
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
