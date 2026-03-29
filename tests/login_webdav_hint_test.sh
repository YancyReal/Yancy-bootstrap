#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_contains() {
  local haystack="$1"
  local needle="$2"

  if [[ "${haystack}" != *"${needle}"* ]]; then
    printf '断言失败: 输出中未包含 %s\n实际输出:\n%s\n' "${needle}" "${haystack}" >&2
    exit 1
  fi
}

assert_fails_with() {
  local command="$1"
  local needle="$2"
  local output

  if output="$(eval "${command}" 2>&1)"; then
    printf '断言失败: 命令应该失败但成功了\n命令: %s\n' "${command}" >&2
    exit 1
  fi

  assert_contains "${output}" "${needle}"
}

make_bootstrap_root() {
  local temp_dir

  temp_dir="$(mktemp -d "/tmp/devbox-bootstrap test.XXXXXX")"
  cp "${REPO_ROOT}/login-webdav.sh" "${temp_dir}/login-webdav.sh"
  printf '%s\n' "${temp_dir}"
}

test_setup_cc_switch_hint_uses_installed_script_path() {
  local output expected_script expected_command

  BOOTSTRAP_ROOT="$(make_bootstrap_root)"

  # shellcheck disable=SC1091
  source "${REPO_ROOT}/lib/common.sh"
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/lib/cc_switch.sh"

  install_cc_switch() { :; }
  prepare_live_configs() { :; }
  configure_cc_switch_webdav() { :; }
  download_cc_switch_state() { :; }

  output="$(
    BOOTSTRAP_WEBDAV_BASE_URL='' \
    BOOTSTRAP_WEBDAV_USERNAME='' \
    BOOTSTRAP_WEBDAV_PASSWORD='' \
    setup_cc_switch
  )"

  expected_script="${BOOTSTRAP_ROOT}/login-webdav.sh"
  printf -v expected_command 'bash %q' "${expected_script}"

  assert_contains "${output}" "${expected_command}"
}

test_login_webdav_banner_uses_installed_script_path() {
  local output expected_script expected_command

  BOOTSTRAP_ROOT="$(make_bootstrap_root)"

  # shellcheck disable=SC1091
  source "${REPO_ROOT}/lib/common.sh"

  output="$(print_login_webdav_banner)"

  expected_script="${BOOTSTRAP_ROOT}/login-webdav.sh"
  printf -v expected_command 'bash %q' "${expected_script}"

  assert_contains "${output}" "${expected_command}"
}

test_login_webdav_command_fails_when_script_missing() {
  BOOTSTRAP_ROOT="$(mktemp -d "/tmp/devbox-bootstrap missing.XXXXXX")"

  # shellcheck disable=SC1091
  source "${REPO_ROOT}/lib/common.sh"

  assert_fails_with "login_webdav_command" "缺少登录脚本"
}

test_setup_cc_switch_hint_uses_installed_script_path
test_login_webdav_banner_uses_installed_script_path
test_login_webdav_command_fails_when_script_missing
