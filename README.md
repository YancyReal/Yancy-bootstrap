# devbox-bootstrap

用于在全新 `macOS` 或 `Ubuntu` 机器上一条命令恢复开发工作环境。

## 覆盖范围

- 安装 `zsh`、`oh-my-zsh`、常用插件
- 安装 `Node.js` 与 `npm`
- 通过 `npm` 安装 `codex`
- 安装 `cc-switch-cli`
- 通过 WebDAV 下载 `cc-switch` 配置与 `skills`
- 安装 `zellij`、`yazi`、`lazygit`

## 使用方式

```bash
git clone https://github.com/YancyReal/Yancy-bootstrap.git
cd Yancy-bootstrap
BOOTSTRAP_WEBDAV_BASE_URL="https://dav.example.com/cc-switch" \
BOOTSTRAP_WEBDAV_USERNAME="your-user" \
BOOTSTRAP_WEBDAV_PASSWORD="your-password" \
./install.sh
```

## 环境变量

- `BOOTSTRAP_NODE_VERSION`
  选择要安装的 Node 主版本，默认值为 `22`
- `BOOTSTRAP_WEBDAV_BASE_URL`
  `cc-switch config webdav set --base-url` 的值
- `BOOTSTRAP_WEBDAV_USERNAME`
  WebDAV 用户名
- `BOOTSTRAP_WEBDAV_PASSWORD`
  WebDAV 密码
- `BOOTSTRAP_SKIP_CC_SWITCH_SYNC=1`
  只安装 `cc-switch-cli`，跳过 WebDAV 配置与下载
- `BOOTSTRAP_SKIP_CHSH=1`
  跳过 `chsh`，适合容器或 CI

## 说明

- 第一次完整运行前，请确认目标机器允许 `curl`、`git`、`npm` 正常访问外网。
- 本仓库第一版不处理 `~/.ssh`、Git 凭据、`~/.codex/auth.json` 等私密材料。
