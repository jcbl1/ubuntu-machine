# 插件

插件都是普通 Bash 脚本。执行器按文件名字典序执行所有已启用插件，因此用数字前缀（`010-`、`020-`……）控制顺序。

镜像只包含执行器（`/usr/local/sbin/run-plugins`），插件脚本仍在仓库 checkout 中。请从 checkout 执行 `plugins/bin/run-plugins`；在 Apple container machine 中，该 checkout 可直接通过挂载的 macOS 家目录访问。

## 目录结构

```text
plugins/
├── bin/run-plugins        # 构建期/运行期共用的执行器
├── available/             # 所有插件
├── enabled/               # 仅放软链接；启用 = ln -s，禁用 = rm
└── private/               # 本地私密文件，由 080-private 落位
```

`plugins/enabled/` 与 `plugins/private/` 被 git 忽略。

## 启用 / 禁用

```bash
ln -s ../available/050-my-plugin plugins/enabled/050-my-plugin   # 启用
rm plugins/enabled/050-my-plugin                                 # 禁用
```

`enabled/` 是本地状态，不属于仓库内容。

## 插件约定

- 纯 Bash，由 `bash` 按文件名顺序执行
- 自包含：需要软件包时自行安装，结束前清理
  （`apt-get clean && rm -rf /var/lib/apt/lists/*`）
- 非交互：执行器导出 `DEBIAN_FRONTEND=noninteractive`
- 不要写入插件目录；构建期该目录以只读方式挂载
- 幂等：可重复执行
- 用户级插件检查 `TARGET_USER`，为空时跳过（构建期）
- 仅 machine 插件检查 `/sbin.machine/init` 或 `/etc/.machine.initialized`，否则跳过；参见 `170-swapfile`

执行器注入：

| 变量 | 含义 |
|---|---|
| `PLUGIN_NAME` | 插件脚本的文件名 |
| `DEBIAN_FRONTEND` | `noninteractive` |
| `TARGET_USER` | 用户级配置的目标用户；解析不到时为空 |
| `PLUGIN_ROOT` | 从仓库布局执行时的 `plugins/` 目录 |

## 执行器参数

```bash
sudo bash plugins/bin/run-plugins                    # 执行 enabled 全部插件
sudo bash plugins/bin/run-plugins --proxy URL        # 导出 http(s)_proxy/all_proxy
sudo bash plugins/bin/run-plugins --dry-run          # 只列出，不执行
sudo bash plugins/bin/run-plugins --enabled DIR      # 使用其他 enabled 目录
sudo bash plugins/bin/run-plugins --target-user USER # 指定目标用户
```

`TARGET_USER` 解析顺序：`--target-user`、`$TARGET_USER`、`$SUDO_USER`、首个 HOME 在 `/home/` 下的非 root 用户。任一插件失败时执行器返回非零。

## 只执行部分插件

```bash
mkdir -p /tmp/plugins
ln -s "$PWD/plugins/available/150-java" /tmp/plugins/150-java
ln -s "$PWD/plugins/available/155-uv" /tmp/plugins/155-uv
sudo bash plugins/bin/run-plugins /tmp/plugins
```

## 插件目录

| 插件 | 作用 | 阶段 |
|---|---|---|
| `010-example` | 示例：安装 htop 并写 `/etc/motd` | 构建期 |
| `020-codex` | OpenAI Codex CLI（官方安装脚本，系统级） | 构建期 |
| `020-opencode` | opencode 系统级安装到 `/usr/local/bin`；新环境通常改用 090 | 构建期 |
| `030-cli-tools` | git、zsh、tmux、fzf、ripgrep、fd、bat、btop、htop、ncdu、lsof、rsync、vim、strace、unzip、file、less、pandoc | 构建/运行 |
| `035-build-essential` | make、gcc、g++、libc-dev | 构建/运行 |
| `040-zsh` | oh-my-zsh、zsh-autosuggestions、`.zshrc`、`all-in-one.zsh`、bash/profile 环境块 | 运行期 |
| `045-proxychains` | proxychains4 与指向宿主机代理的 `/etc/proxychains4.conf` | 构建/运行 |
| `050-tmux` | `~/.tmux.conf`、tpm 及插件无头安装 | 运行期 |
| `060-yazi` | yazi/ya 二进制（GitHub release）与 `yazi.toml` | 运行期 |
| `070-dotfiles` | btop 配置、ncdu 配置与 `~/ncdu-exclude.txt` | 运行期 |
| `080-private` | 从 `private/` 落位 gitconfig、authorized_keys、bot `.env`、`service.json` | 运行期 |
| `090-opencode` | OpenCode V2 用户配置（`opencode.jsonc`、`cli.json`、notifier） | 运行期 |
| `095-opencode-server` | `opencode-server.service`（OpenCode 后台服务） | 运行期 |
| `100-nvm` | nvm（不预装 Node 版本） | 运行期 |
| `110-rust` | rustup + stable；可选编译 tauri-cli（较慢） | 运行期 |
| `120-go` | golang-go（Ubuntu 24.04 源） | 构建/运行 |
| `130-tauri-deps` | Tauri/GUI 编译依赖（gtk、webkit、mingw 等，体积大） | 构建/运行 |
| `140-container-tidy` | 清理脚本 + 每周/开机两个 systemd timer | 构建/运行 |
| `150-java` | Eclipse Temurin 17 JDK（Adoptium apt 源） | 构建/运行 |
| `155-uv` | uv（用户级，`~/.local/bin`） | 运行期 |
| `160-opencode-telegram-bot` | Telegram bot 启动器 + `opencode-telegram-bot.service` | 运行期 |
| `170-swapfile` | 为 container machine 的 rootfs 可选创建 swapfile；立即启用并安装 `machine-swapfile.service` 供后续启动使用 | 运行期（仅 machine） |

## 构建期行为

构建期没有目标用户，因此用户级插件（`040`、`050`、`060`、`070`、`080`、`090`、`095`、`100`、`110`、`155`、`160`）会自动跳过。容器创建后执行 `run-plugins` 时才会落位。

`170-swapfile` 仅在 container machine 内运行；构建期和普通容器内会自动跳过，避免把 swapfile 写进镜像。

## 相关文档

- 服务配置：[服务](services.md)
- 密钥与环境变量：[配置](configuration.md)
