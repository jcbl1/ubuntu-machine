# ubuntu-machine

基于 Ubuntu 24.04 的 systemd 容器基础镜像（sshd、systemd 已配置），内置插件系统，用于安装自定义软件、完成自定义设置。

## 镜像

Docker Hub：[`jcbl1/ubuntu-machine`](https://hub.docker.com/r/jcbl1/ubuntu-machine)

| Tag | 说明 |
| --- | --- |
| `latest` | 最新正式版本 |
| `vX.Y` | 项目版本 |
| `vX.Y-noble` | 项目版本 + Ubuntu codename |
| `vX.Y-24.04` | 项目版本 + Ubuntu 版本号 |
| `vX.Y-nobleYYYYMMDD[.N]` | 项目版本 + 构建所用基础镜像快照 |

同一次发布的以上 tag 指向同一镜像 digest。例如 `v1.2` 发布时：

```bash
docker pull jcbl1/ubuntu-machine:latest
docker pull jcbl1/ubuntu-machine:v1.2
docker pull jcbl1/ubuntu-machine:v1.2-noble
docker pull jcbl1/ubuntu-machine:v1.2-24.04
docker pull jcbl1/ubuntu-machine:v1.2-noble20261024.1
```

## 构建

```bash
docker build -t local/ubuntu-machine .
```

默认基础镜像为 `ubuntu:24.04`，可通过 `BASE_IMAGE` 指定其他 tag 或快照：

```bash
docker build --build-arg BASE_IMAGE=ubuntu:noble-20261024.1 -t local/ubuntu-machine .
```

## 发版

版本号只来自 git tag，格式为 `vX.Y`。确认要发布的改动已在 master 上后：

```bash
git tag v1.2
git push origin v1.2
```

推送 tag 后，`release` workflow 会自动：

1. 校验 tag 格式，且该 commit 必须在 master 上
2. 解析 `Dockerfile` 中 `BASE_IMAGE` 对应的 Ubuntu 快照 tag
3. 以该快照为基础镜像构建 `linux/amd64,linux/arm64`，推送 `latest`、`vX.Y`、`vX.Y-noble`、`vX.Y-24.04`、`vX.Y-nobleYYYYMMDD[.N]`
4. 创建 GitHub Release（自动生成 changelog）

注意：

- 已推送的 tag 不要移动或删除；修复问题请发布新版本
- `latest` 只随正式发版移动；日常 master 推送只做构建验证，不推送镜像
- workflow 会拒绝比当前最新 Release 更旧的版本号，避免误操作把 `latest` 回退
- 需要仓库变量 `DOCKERHUB_IMAGE`（如 `jcbl1/ubuntu-machine`），以及 secrets `DOCKERHUB_USERNAME`、`DOCKERHUB_TOKEN`

## 插件

```
plugins/
├── bin/run-plugins        # 执行器（构建期/运行期共用，按文件名顺序执行 enabled 插件）
├── available/             # 所有插件
└── enabled/               # 仅放软链接，启用 = ln -s，禁用 = rm
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
- 执行器注入 `PLUGIN_NAME`、`DEBIAN_FRONTEND=noninteractive`；任一插件失败即中止构建
- `plugins/enabled/` 内容不入库（`.gitkeep` 除外），可参考 `plugins/available/010-example`

## 运行时初始化（容器创建后）

同一插件池也可以在运行中的容器里执行，用于用户级配置（`$HOME` 下文件）：

```bash
sudo bash plugins/bin/run-plugins                    # 执行 enabled 全部插件
sudo bash plugins/bin/run-plugins --proxy http://192.168.64.1:20121
sudo bash plugins/bin/run-plugins --dry-run          # 只预览
```

- 执行器注入 `TARGET_USER`（默认 `SUDO_USER`）与 `PLUGIN_ROOT`；插件要求幂等，
  且在无目标用户（构建期）时自动跳过用户级部分，因此 `enabled/` 可构建/运行共用
- 私密内容放 `plugins/private/`（不入库），由 `080-private` 落位
