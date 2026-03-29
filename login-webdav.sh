#!/usr/bin/env bash
set -euo pipefail

# 坚果云 WebDAV 交互式登录脚本

BOOTSTRAP_WEBDAV_BASE_URL="${BOOTSTRAP_WEBDAV_BASE_URL:-}"
BOOTSTRAP_WEBDAV_USERNAME="${BOOTSTRAP_WEBDAV_USERNAME:-}"
BOOTSTRAP_WEBDAV_PASSWORD="${BOOTSTRAP_WEBDAV_PASSWORD:-}"

echo ""
echo "==> 坚果云 WebDAV 登录"
echo ""
echo "请输入您的坚果云信息："
echo "(直接回车使用默认值 https://dav.jianguoyun.com/dav/)"
echo ""

read -rp "WebDAV 地址 [$BOOTSTRAP_WEBDAV_BASE_URL]: " input_url
read -rp "用户名: " input_user
read -rsp "密码: " input_pass
echo ""

base_url="${input_url:-${BOOTSTRAP_WEBDAV_BASE_URL:-https://dav.jianguoyun.com/dav/}"
username="${input_user:-${BOOTSTRAP_WEBDAV_USERNAME}}"
password="${input_pass:-${BOOTSTRAP_WEBDAV_PASSWORD}}"

if [[ -z "${username}" ]] || [[ -z "${password}" ]]; then
  echo "错误: 用户名和密码不能为空"
  exit 1
fi

if ! command -v cc-switch >/dev/null 2>&1; then
  echo "错误: cc-switch 未安装，请先运行 bootstrap.sh"
  exit 1
fi

echo ""
echo "==> 配置 WebDAV..."
cc-switch config webdav set \
  --base-url "${base_url}" \
  --username "${username}" \
  --password "${password}" \
  --enable

echo ""
echo "==> 检查连接..."
cc-switch config webdav check-connection

echo ""
echo "==> 同步配置..."
cc-switch config webdav download

echo ""
echo "✅ 登录成功!"