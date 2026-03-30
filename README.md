# devbox-bootstrap

用于在全新 `macOS` 或 `Ubuntu` 机器上一条命令恢复开发工作环境。

## 覆盖范围

- 安装 `zsh`、`oh-my-zsh`、常用插件
- 安装 `tmux` 与 `oh-my-tmux`
- 安装 `Node.js` 与 `npm`
- 通过 `npm` 安装 `codex`
- 安装 `cc-switch-cli`
- 通过 WebDAV 下载 `cc-switch` 配置与 `skills`
- 安装 `zellij`、`yazi`、`lazygit`
- 在 Ubuntu 下自动检查 `apt` 官方源，非国内源时切换为阿里源

## 使用方式

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/YancyReal/Yancy-bootstrap/main/bootstrap.sh | bash
```

### 手动克隆

```bash
git clone https://github.com/YancyReal/Yancy-bootstrap.git
cd Yancy-bootstrap
BOOTSTRAP_WEBDAV_BASE_URL="https://dav.example.com/cc-switch" \
BOOTSTRAP_WEBDAV_USERNAME="your-user" \
BOOTSTRAP_WEBDAV_PASSWORD="your-password" \
./install.sh
```

## 环境变量

- `BOOTSTRAP_GITHUB_REPO`
  GitHub 仓库地址，格式为 `account/repo`，默认值为 `YancyReal/Yancy-bootstrap`
- `BOOTSTRAP_GITHUB_REF`
  Git 分支或标签，默认为 `main`
- `BOOTSTRAP_INSTALL_DIR`
  安装目录，默认为 `~/.local/share/devbox-bootstrap`
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
- `BOOTSTRAP_INTERACTIVE=1`
  启用交互式模式，在终端中提示用户输入 WebDAV 凭据（默认使用坚果云）

## 说明

- 第一次完整运行前，请确认目标机器允许 `curl`、`git`、`npm` 正常访问外网。
- 安装 `oh-my-tmux` 时会创建 `~/.tmux`，并链接 `~/.tmux.conf`；若不存在 `~/.tmux.conf.local`，则自动生成一份。
- Ubuntu 仅会调整官方 `apt` 源，检测到不是国内镜像时自动切换为阿里源，并备份原文件为 `.bootstrap.bak`
- 本仓库第一版不处理 `~/.ssh`、Git 凭据、`~/.codex/auth.json` 等私密材料。
