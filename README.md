# ubuntu-machine

基于 Ubuntu 24.04 的 systemd 容器基础镜像（sshd、systemd 已配置），内置插件系统，用于安装自定义软件、完成自定义设置。

## 构建

```bash
docker build -t local/ubuntu-machine .
```

构建上下文会排除 `.git` 与 `plugins/private/`（见 `.dockerignore`）。

## 插件系统

```
plugins/
├── bin/run-plugins        # 执行器（构建期/运行期共用，按文件名顺序执行 enabled 插件）
├── available/             # 所有插件
├── enabled/               # 仅放软链接，启用 = ln -s，禁用 = rm（不入库）
└── private/               # 私密文件（不入库，由 080-private 落位）
```

启用 / 禁用（类似 nginx 的 sites-enabled）：

```bash
ln -s ../available/050-my-plugin plugins/enabled/050-my-plugin   # 启用
rm plugins/enabled/050-my-plugin                                 # 禁用
```

约定：

- 纯 bash 脚本，按文件名字典序执行，用数字前缀（`010-`、`020-`）控制顺序
- 自包含：需要软件包时自己 `apt-get update`，结束前自己 `apt-get clean && rm -rf /var/lib/apt/lists/*`
- 构建以只读方式挂载插件目录（`/opt/plugins`），脚本请勿写入该目录，临时文件用 `/tmp`
- 执行器注入 `PLUGIN_NAME`、`DEBIAN_FRONTEND=noninteractive`；任一插件失败即中止
- 用户级插件要求幂等，且在无目标用户（构建期）时自动跳过，因此 `enabled/` 可构建/运行共用

## 运行时初始化

同一插件池也可以在运行中的容器里执行：

```bash
sudo bash plugins/bin/run-plugins                    # 执行 enabled 全部插件
sudo bash plugins/bin/run-plugins --proxy http://192.168.64.1:20121
sudo bash plugins/bin/run-plugins --dry-run          # 只预览
sudo bash plugins/bin/run-plugins --enabled DIR      # 指定其他 enabled 目录
sudo bash plugins/bin/run-plugins --target-user USER # 指定用户级配置的目标用户
```

- 执行器解析 `TARGET_USER`（`--target-user` > `$TARGET_USER` > `$SUDO_USER` > 首个 HOME 在
  `/home/` 下的非 root 用户）；解析不到则置空，用户级插件自动跳过
- 仓库布局下额外注入 `PLUGIN_ROOT`（`plugins/` 目录），供 `080-private` 定位私密文件
- 私密内容放 `plugins/private/`（不入库），由 `080-private` 落位

## 插件目录

| 插件 | 作用 | 阶段 |
|---|---|---|
| `010-example` | 示例：安装 htop 并写 `/etc/motd` | 构建期 |
| `020-codex` | OpenAI Codex CLI（官方安装脚本，系统级） | 构建期 |
| `020-opencode` | opencode 系统级安装（`/usr/local/bin`；新环境通常改用 090） | 构建期 |
| `030-cli-tools` | git、zsh、tmux、fzf、ripgrep、fd、bat、btop、htop、ncdu、lsof、rsync、vim、strace、unzip、file、less、pandoc | 构建/运行 |
| `035-build-essential` | make、gcc、g++、libc-dev | 构建/运行 |
| `040-zsh` | oh-my-zsh、zsh-autosuggestions、`.zshrc`、`all-in-one.zsh`、bash/profile 环境块 | 运行期 |
| `045-proxychains` | proxychains4 + 指向宿主机代理的 `/etc/proxychains4.conf` | 构建/运行 |
| `050-tmux` | `~/.tmux.conf`、tpm 及插件无头安装 | 运行期 |
| `060-yazi` | yazi/ya 二进制（GitHub release）与 `yazi.toml` | 运行期 |
| `070-dotfiles` | btop 配置、ncdu 配置与 `~/ncdu-exclude.txt` | 运行期 |
| `080-private` | `private/` 下的 gitconfig、authorized_keys、bot `.env` 落位 | 运行期 |
| `090-opencode` | OpenCode V2 用户配置（`opencode.jsonc`、`cli.json`、notifier） | 运行期 |
| `095-opencode-server` | `opencode-server.service`（opencode 后台服务） | 运行期 |
| `100-nvm` | nvm（不预装 Node 版本） | 运行期 |
| `110-rust` | rustup + stable，可选 tauri-cli（默认编译，较慢） | 运行期 |
| `120-go` | golang-go（Ubuntu 24.04 源） | 构建/运行 |
| `130-tauri-deps` | Tauri/GUI 编译依赖（gtk、webkit、mingw 等，体积大） | 构建/运行 |
| `140-container-tidy` | 周期性清理脚本 + 每周/开机两个 systemd timer | 构建/运行 |
| `150-java` | Eclipse Temurin 17 JDK（Adoptium apt 源） | 构建/运行 |
| `155-uv` | uv（用户级，`~/.local/bin`） | 运行期 |
| `160-opencode-telegram-bot` | Telegram bot 启动器 + `opencode-telegram-bot.service` | 运行期 |

当前容器启用的插件见本地 `plugins/enabled/`（该目录不入库）。

## systemd 服务

| 单元 | 来源 | 说明 |
|---|---|---|
| `opencode-server.service` | `095-opencode-server` | 以目标用户运行 `opencode service start/stop` |
| `opencode-telegram-bot.service` | `160-opencode-telegram-bot` | 依赖 server；仅当 `.env` 存在时启动 |
| `container-tidy.timer` | `140-container-tidy` | 每周日 06:30 清理 |
| `container-tidy-boot.timer` | `140-container-tidy` | 开机 15 分钟后清理 |

常用命令：

```bash
systemctl status opencode-server opencode-telegram-bot
systemctl list-timers 'container-tidy*'
sudo systemctl restart opencode-server.service   # 升级 opencode 后切换后端
sudo journalctl -u opencode-telegram-bot -n 100
```

`opencode-server` 的端口、密码、代理环境在 `~/.config/opencode/service.json`，由 opencode
自己管理，不入库。需要代理时：

```bash
opencode service set env http_proxy  http://HOST:PORT
opencode service set env https_proxy http://HOST:PORT
opencode service set env all_proxy   http://HOST:PORT
```

## 配置与密钥

- `plugins/private/gitconfig` → `~/.gitconfig`
- `plugins/private/authorized_keys` → `~/.ssh/authorized_keys`（600）
- `plugins/private/opencode-telegram-bot.env` → `~/.config/opencode-telegram-bot/.env`（600）
- OpenCode 认证（`opencode auth login`）产生的凭据不纳入本仓库
- `~/.config/opencode/` 下的 `opencode.jsonc`、`cli.json` 由 `090-opencode` 声明式部署；
  `service.json`、会话数据、notifier 状态属于运行时状态，不由插件管理

OpenCode 配置使用 V2 原生格式：MCP 服务器在 `mcp.servers` 下、用 `disabled` 禁用；
权限使用 `permissions` 数组；websearch 使用 `websearch` 对象。

## 注意

- `plugins/enabled/` 与 `plugins/private/` 被 `.gitignore` 忽略，换机器时需要重新创建软链/放置私密文件
- 构建期没有 `TARGET_USER`，`040/050/060/070/080/090/095/100/110/155/160` 等用户级插件会跳过，
  只在容器创建后执行 `run-plugins` 才落位
- `140-container-tidy` 的每周与开机调度使用两个独立 timer，避免 `OnCalendar` + `OnBootSec`
  混用导致 systemd 不再重排每周任务
