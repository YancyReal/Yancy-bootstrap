## [ERR-20260330-001] bash-command-substitution

**Logged**: 2026-03-30T00:23:37+08:00
**Priority**: medium
**Status**: pending
**Area**: tests

### Summary
在 shell helper 中通过命令替换调用会失败的函数时，错误可能被吞掉，导致测试误以为函数成功。

### Error
```text
断言失败: 命令应该失败但成功了
命令: login_webdav_command
```

### Context
- 命令：`bash tests/login_webdav_hint_test.sh`
- 触发点：`login_webdav_command` 内部使用 `script_path="$(login_webdav_script_path)"`
- 相关行为：`login_webdav_script_path` 调用 `die` 失败后，外层 helper 没有显式传播非零退出状态

### Suggested Fix
对命令替换结果显式追加 `|| return 1`，确保错误状态不会被吞掉。

### Metadata
- Reproducible: yes
- Related Files: lib/common.sh, tests/login_webdav_hint_test.sh

---
