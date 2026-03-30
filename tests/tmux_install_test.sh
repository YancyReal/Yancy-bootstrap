#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORIGINAL_PATH="${PATH}"

assert_contains() {
  local haystack="$1"
  local needle="$2"

  if [[ "${haystack}" != *"${needle}"* ]]; then
    printf '断言失败: 输出中未包含 %s\n实际输出:\n%s\n' "${needle}" "${haystack}" >&2
    exit 1
  fi
}

assert_equals() {
  local actual="$1"
  local expected="$2"

  if [[ "${actual}" != "${expected}" ]]; then
    printf '断言失败: 期望 %s，实际 %s\n' "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_file_contains() {
  local file_path="$1"
  local needle="$2"
  local content

  content="$(cat "${file_path}")"
  assert_contains "${content}" "${needle}"
}

assert_symlink_target() {
  local link_path="$1"
  local expected_target="$2"
  local actual_target

  actual_target="$(readlink "${link_path}")"
  assert_equals "${actual_target}" "${expected_target}"
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

make_test_home() {
  mktemp -d "/tmp/devbox-bootstrap tmux.XXXXXX"
}

write_fake_executable() {
  local file_path="$1"
  local body="${2:-#!/usr/bin/env bash
exit 0
}"

  mkdir -p "$(dirname "${file_path}")"
  printf '%s\n' "${body}" > "${file_path}"
  chmod +x "${file_path}"
}

mock_tmux_lookup() {
  command() {
    if [[ "$1" == "-v" ]] && [[ "${2:-}" == "tmux" ]]; then
      if [[ -n "${TEST_TMUX_PATH:-}" ]] && [[ -x "${TEST_TMUX_PATH}" ]]; then
        printf '%s\n' "${TEST_TMUX_PATH}"
        return 0
      fi
      return 1
    fi

    builtin command "$@"
  }
}

load_tools() {
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/lib/common.sh"
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/lib/tools.sh"
}

run_test() {
  local test_name="$1"
  (
    "${test_name}"
  )
}

test_install_terminal_tools_runs_tmux_before_oh_my_tmux() {
  local test_home

  test_home="$(make_test_home)"
  TEST_CALL_LOG="${test_home}/calls.log"

  load_tools

  install_tmux() { printf 'install_tmux\n' >> "${TEST_CALL_LOG}"; }
  install_oh_my_tmux() { printf 'install_oh_my_tmux\n' >> "${TEST_CALL_LOG}"; }
  install_zellij() { printf 'install_zellij\n' >> "${TEST_CALL_LOG}"; }
  install_yazi() { printf 'install_yazi\n' >> "${TEST_CALL_LOG}"; }
  install_lazygit() { printf 'install_lazygit\n' >> "${TEST_CALL_LOG}"; }

  install_terminal_tools

  assert_equals \
    "$(cat "${TEST_CALL_LOG}")" \
    $'install_tmux\ninstall_oh_my_tmux\ninstall_zellij\ninstall_yazi\ninstall_lazygit'
}

test_install_oh_my_tmux_creates_config_without_overwriting_local() {
  local test_home temp_bin original_local_config

  test_home="$(make_test_home)"
  temp_bin="${test_home}/bin"
  mkdir -p "${temp_bin}"

  HOME="${test_home}"
  PATH="${temp_bin}:${ORIGINAL_PATH}"
  TEST_TMUX_PATH="${temp_bin}/tmux"

  write_fake_executable "${temp_bin}/tmux"
  mock_tmux_lookup

  load_tools

  git() {
    if [[ "$1" == "clone" ]]; then
      local target_dir="${4}"
      mkdir -p "${target_dir}"
      printf '# main config\n' > "${target_dir}/.tmux.conf"
      printf '# local template\n' > "${target_dir}/.tmux.conf.local"
      return 0
    fi

    builtin command git "$@"
  }

  original_local_config='# keep my local config'
  printf '%s\n' "${original_local_config}" > "${HOME}/.tmux.conf.local"

  install_oh_my_tmux

  [[ -d "${HOME}/.tmux" ]] || {
    printf '断言失败: 未创建 %s\n' "${HOME}/.tmux" >&2
    exit 1
  }
  [[ -L "${HOME}/.tmux.conf" ]] || {
    printf '断言失败: 未创建符号链接 %s\n' "${HOME}/.tmux.conf" >&2
    exit 1
  }
  assert_symlink_target "${HOME}/.tmux.conf" "${HOME}/.tmux/.tmux.conf"
  assert_file_contains "${HOME}/.tmux.conf.local" "${original_local_config}"
}

test_install_oh_my_tmux_fails_without_tmux() {
  local test_home temp_bin

  test_home="$(make_test_home)"
  temp_bin="${test_home}/bin"
  mkdir -p "${temp_bin}"

  HOME="${test_home}"
  PATH="${temp_bin}:${ORIGINAL_PATH}"
  TEST_TMUX_PATH="${temp_bin}/tmux"
  mock_tmux_lookup

  load_tools

  assert_fails_with "install_oh_my_tmux" "tmux 未安装"
}

test_install_tmux_uses_package_manager() {
  local test_home temp_bin

  test_home="$(make_test_home)"
  temp_bin="${test_home}/bin"
  mkdir -p "${temp_bin}"

  HOME="${test_home}"
  PATH="${temp_bin}:${ORIGINAL_PATH}"
  TEST_INSTALLED_PACKAGES=""
  TEST_TMUX_PATH="${temp_bin}/tmux"
  TEST_TEMP_BIN="${temp_bin}"
  mock_tmux_lookup

  load_tools

  install_packages() {
    TEST_INSTALLED_PACKAGES="$*"
    write_fake_executable "${TEST_TEMP_BIN}/tmux"
  }

  install_tmux

  assert_equals "${TEST_INSTALLED_PACKAGES}" "tmux"
}

run_test test_install_terminal_tools_runs_tmux_before_oh_my_tmux
run_test test_install_oh_my_tmux_creates_config_without_overwriting_local
run_test test_install_oh_my_tmux_fails_without_tmux
run_test test_install_tmux_uses_package_manager
