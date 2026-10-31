# Apple container machine

本项目最重要的用途是作为 [Apple container](https://github.com/apple/container) machine 的基础镜像。Container machine 是在 Apple silicon 上以轻量 VM 方式运行、与 macOS 深度集成的持久 Linux 环境。

## Container machine 提供什么

- 由镜像自带 init 系统启动的持久 Linux 环境（本镜像使用 systemd）
- 自动创建与 macOS 用户同名、同 UID/GID 的 Linux 账户和家目录
- 将 macOS 家目录以相同路径（`/Users/<username>`）读写挂载进 guest
- 在 macOS 家目录下执行 `container machine run` 时，shell 会从对应目录启动
- 映射用户拥有免密 `sudo`
- `container machine stop` 后状态仍然保留，下次启动可继续使用

## 要求

- Apple silicon Mac
- 你的 `container` 版本所支持的 macOS（见 [container README](https://github.com/apple/container#requirements)）
- 已安装 `container` 并启动系统服务：

```bash
container system start
```

## 创建和使用

```bash
container machine create jcbl1/ubuntu-machine:latest --name ubuntu
container machine set-default ubuntu
container machine run -n ubuntu
```

执行单条命令：

```bash
container machine run -n ubuntu uname -a
```

`machine` 子命令的别名是 `m`：

```bash
m run -n ubuntu
```

管理 machine：

```bash
container machine ls
container machine inspect ubuntu
container machine stop ubuntu
container machine rm ubuntu
```

## 用户与家目录映射

`container machine` 会在首次启动时创建 guest 账户，默认与 macOS 账户一致：

- 相同的用户名和 UID/GID
- Linux 家目录在 `/home/<username>`
- 通过 `/etc/sudoers.d/<username>` 提供免密 sudo
- macOS 家目录挂载到 `/Users/<username>`，沿用 macOS 用户权限

在 macOS 家目录下执行 `container machine run` 时，Linux 进程会从对应目录启动。因此 Mac 上的仓库可以直接在 machine 内使用，不需要复制文件：

```bash
cd /Users/<you>/path/to/ubuntu-machine
sudo bash plugins/bin/run-plugins
```

如有需要，可在创建时覆盖账户：

```bash
container machine create --user devuser --uid 1500 --gid 1600 \
  jcbl1/ubuntu-machine:latest --name ubuntu
```

## 在 container machine 中使用插件

插件脚本有意不打进镜像；镜像只提供执行器，插件从仓库 checkout 执行。首次启动的典型流程：

```bash
container machine run -n ubuntu -- bash -lc '
  cd /Users/<you>/path/to/ubuntu-machine &&
  sudo bash plugins/bin/run-plugins --dry-run
'
```

确认无误后去掉 `--dry-run` 执行。插件目录与参数见[插件](plugins.md)。

## 本地构建镜像

```bash
container build -t local/ubuntu-machine:latest .
container machine create local/ubuntu-machine:latest --name ubuntu
```

Dockerfile 满足 Apple container machine 的镜像要求：安装 systemd、提供 `/sbin/init`，并包含创建用户所需的常见基础工具。

## 安全提示

Apple 文档明确指出：container machine 比普通容器更接近直接在 Mac 上运行程序：

- 拥有全部 Linux capabilities
- 家目录以读写方式挂载
- SSH agent 会转发进 guest
- 镜像的 init 进程以 root 运行

只应从你信任的镜像创建 container machine。使用自定义构建前，请先审查 Dockerfile 和插件。

## 相关文档

- [使用](usage.md)
- [插件](plugins.md)
- [服务](services.md)
