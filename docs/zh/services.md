# systemd 服务

镜像启用了 systemd。运行期插件可以为目标用户安装并启用服务。

| 单元 | 安装插件 | 用途 |
|---|---|---|
| `opencode-server.service` | `095-opencode-server` | OpenCode V2 后台服务 |
| `opencode-telegram-bot.service` | `160-opencode-telegram-bot` | Telegram bot，依赖 OpenCode server |
| `container-tidy.timer` | `140-container-tidy` | 每周清理 |
| `container-tidy-boot.timer` | `140-container-tidy` | 开机 15 分钟后清理 |

## OpenCode server

`095-opencode-server` 写入 `/etc/systemd/system/opencode-server.service`，执行：

```text
opencode service start   # ExecStart
opencode service stop    # ExecStop
```

服务以目标用户身份运行，优先使用 `~/.opencode/bin/opencode`，找不到时回退到 `PATH` 中的 `opencode`。

端口、监听地址、密码和代理环境保存在 `~/.config/opencode/service.json`。`080-private` 可选择从 `plugins/private/opencode-service.json`（600，不入库）落位该文件，使所有容器沿用同一个本地 API 密码和代理配置；没有该文件时，OpenCode 首次启动会随机生成密码。默认监听 `127.0.0.1:49374`；把 `hostname` 设为 `0.0.0.0` 后宿主可访问（API 仍需密码）。配置这些托管值：

```bash
opencode service set hostname 0.0.0.0
opencode service set port 49374
opencode service set env HTTP_PROXY  http://HOST:PORT
opencode service set env HTTPS_PROXY http://HOST:PORT
opencode service set env NO_PROXY    localhost,127.0.0.1,::1
```

`NO_PROXY` 必须包含回环地址：CLI 与后台服务之间走本地 HTTP。修改这些值会停止正在运行的服务，改完需要重新启动。

`ExecStart` 是幂等的：OpenCode 会复用已运行且健康的后端。升级二进制后，重启 unit 以切换后端：

```bash
sudo systemctl restart opencode-server.service
```

## Telegram bot

`160-opencode-telegram-bot` 安装：

- `~/opencode-telegram-bot/run-bot.sh`
- `~/opencode-telegram-bot/.nvmrc`
- `~/.config/opencode-telegram-bot/`（`.env`、settings、logs）
- `/etc/systemd/system/opencode-telegram-bot.service`

unit 以目标用户运行 `run-bot.sh`，失败后自动重启。只有 `~/.config/opencode-telegram-bot/.env` 存在时才会 enable/启动，避免没有凭据时反复重启。`.env` 通常由 `080-private` 从 `plugins/private/opencode-telegram-bot.env` 落位。

启动器依赖 `100-nvm`（nvm）安装并切换到固定 Node 版本。Telegram 流量走 bot 自带的 `TELEGRAM_PROXY_URL`（配置在 `.env` 中）；启动器不再用 `proxychains4` 包裹整个进程，否则发往本机 OpenCode API 的请求也会被代理。

## 清理定时器

`140-container-tidy` 安装两个独立 timer：

- `container-tidy.timer`：每周日 06:30（`Persistent=true`）
- `container-tidy-boot.timer`：开机 15 分钟后

两者都触发 `container-tidy.target`，由它启动用户级和 root 级清理 service。清理范围与配置见[维护](maintenance.md)。

## 常用命令

```bash
systemctl status opencode-server opencode-telegram-bot
systemctl list-timers 'container-tidy*'
sudo journalctl -u opencode-telegram-bot -n 100
sudo systemctl restart opencode-server.service
```

`container-tidy-boot.timer` 触发后 `NEXT` 显示 `-` 是正常现象：它是一次性开机 timer，每周任务由 `container-tidy.timer` 负责。
