# 配置、密钥与环境变量

## 密钥与私密文件

私密文件放在 `plugins/private/`，该目录被 git 忽略，并从 Docker 构建上下文中排除。

| 来源 | 目标 | 权限 |
|---|---|---|
| `plugins/private/gitconfig` | `~/.gitconfig` | 644 |
| `plugins/private/authorized_keys` | `~/.ssh/authorized_keys` | 600（`.ssh` 为 700） |
| `plugins/private/opencode-telegram-bot.env` | `~/.config/opencode-telegram-bot/.env` | 600 |

`080-private` 会跳过不存在的文件，且不会触碰 SSH 私钥或 OpenCode 凭据。

通过 `opencode auth login` 产生的凭据不纳入本仓库。

## OpenCode 配置

`090-opencode` 以 OpenCode V2 原生格式部署 `~/.config/opencode/opencode.jsonc`、`cli.json` 和 `opencode-notifier.json`：

- MCP 服务器位于 `mcp.servers`
- 用 `disabled: true` 禁用服务器（不是 `enabled: false`）
- 权限使用有序的 `permissions` 数组，动作包括 `shell`、`webfetch`、`websearch`
- Web search 使用 `websearch` 对象配置

以下属于运行时状态（插件不完全管理）：

- `~/.config/opencode/service.json`（监听地址/端口、密码、代理环境；可选由 `080-private` 从 `plugins/private/opencode-service.json` 落位）
- `~/.local/share/opencode/` 下的会话数据
- notifier 状态文件

## 插件配置文件

运行期插件设置放在仓库根目录的 `.env`。该文件被 git 忽略，并排除在 Docker 构建上下文之外，不会进入镜像。

```bash
cp .env.example .env
$EDITOR .env
```

`run-plugins` 运行期默认读取 `.env`；可用 `--env-file FILE` 指定其他文件。构建期不会读取它。

- 格式：`KEY=value`，可带 `export`，整行 `#` 注释，含空格的值用单/双引号包裹
- 列表值是空格分隔的字符串（如 `YAZI_NOOP_PATHS`）
- 空值表示禁用（`YAZI_NOOP_PATHS=`）
- 环境变量优先；本文件只补充尚未设置的变量
- 文件只解析、不 `source`，值不会被执行
- 密钥放 `plugins/private/`，不要放这里

## 环境变量

下表中的设置可以写进 `.env`，也可以作为环境变量导出；环境变量优先于 `.env`。

| 变量 | 使用方 | 作用 |
|---|---|---|
| `PROXY_HOST`、`PROXY_PORT` | `045-proxychains`、zsh `pc` 别名 | 宿主机代理地址；默认 `192.168.64.1:20121` |
| `UV_VERSION` | `155-uv` | 安装指定 uv 版本，而不是 latest |
| `YAZI_VERSION` | `060-yazi` | 固定 yazi release tag，而不是 latest |
| `YAZI_NOOP_PATHS` | `060-yazi` | 禁用 MIME 探测、预览与预加载的路径 glob 列表（空格分隔；默认 `/Users/<user>/Documents/sync/cloudreve/**`，留空则禁用） |
| `INSTALL_TAURI_CLI` | `110-rust` | 设为 `0` 可跳过耗时的 tauri-cli 编译 |
| `TELEGRAM_BOT_NODE_VERSION` | `160-opencode-telegram-bot` | bot 使用的 Node 版本（默认 `v22.23.2`） |
| `SWAPFILE_SIZE` | `170-swapfile` | container machine 的 swapfile 大小（默认 `4G`，如 `512M`、`8G`） |
| `SWAPFILE_PATH` | `170-swapfile` | swapfile 路径（默认 `/swapfile`）；必须在 ext4/xfs 文件系统，不能放 `/Users` |
| `SWAPFILE_DRY_RUN` | `170-swapfile` | 设为 `1` 只打印计划动作，不做修改 |
| `http_proxy`、`https_proxy`、`all_proxy` | `045`、下载与包管理器 | 标准代理变量；`run-plugins --proxy` 会同时导出三个 |

`170-swapfile` 会安装 `machine-swapfile.service` 实现开机启用。不要在 container machine 里依赖 `/etc/fstab` 的 swap 条目：systemd 会把 machine 识别为容器并忽略它。

`run-plugins` 还支持 `--target-user`，用于默认用户探测不符合预期的容器。

## 被忽略的本地状态

- `plugins/enabled/`：选择启用哪些插件的本地软链
- `plugins/private/`：本地密钥
- `.env`：本地插件配置
- `NOTES.md`、`NOTES.*.md`：本地实施笔记

## 相关文档

- [插件](plugins.md)
- [服务](services.md)
- [使用](usage.md)
