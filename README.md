# ubuntu-machine

基于 Ubuntu 24.04 的 systemd 容器基础镜像（sshd、systemd 已配置），内置构建期插件系统，用于安装自定义软件、完成自定义设置。

## 构建

```bash
docker build -t local/ubuntu-machine .
```

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
