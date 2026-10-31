# 使用

Apple container machine 的用法见 [Apple container machine](apple-container-machine.md)。本页介绍镜像 tag 和通用 OCI/Docker 用法。

## 运行要求

镜像以 `systemd` 作为 PID 1，需要能运行 systemd 容器并访问 cgroups 的运行时。示例使用 `--privileged` 简化配置；生产环境请按运行时能力收窄权限与挂载。

## 镜像 tag

| Tag | 说明 |
|---|---|
| `latest` | 最新正式版本 |
| `vX.Y` | 项目版本 |
| `vX.Y-noble` | 项目版本 + Ubuntu codename |
| `vX.Y-24.04` | 项目版本 + Ubuntu 版本号 |
| `vX.Y-nobleYYYYMMDD[.N]` | 项目版本 + 构建所用 Ubuntu 快照 |

同一次发布的以上 tag 指向同一镜像 digest。例如 `v1.2` 发布时：

```bash
docker pull jcbl1/ubuntu-machine:latest
docker pull jcbl1/ubuntu-machine:v1.2
docker pull jcbl1/ubuntu-machine:v1.2-noble
docker pull jcbl1/ubuntu-machine:v1.2-24.04
docker pull jcbl1/ubuntu-machine:v1.2-noble20261024.1
```

## 运行

通用 Docker / OCI 运行时（systemd）：

```bash
docker run -d --name ubuntu-machine --hostname ubuntu-machine \
  --privileged -p 2222:22 \
  jcbl1/ubuntu-machine:latest

docker exec -it ubuntu-machine systemctl status
```

基础镜像包含 `openssh-server`，但不内置任何凭据。需要通过 SSH 登录时，可用 `080-private` 插件落位 `authorized_keys`（见[配置](configuration.md)），或自行创建用户和密钥。

## 本地构建

```bash
docker build -t local/ubuntu-machine .
```

默认基础镜像为 `ubuntu:24.04`，可用 `BASE_IMAGE` 指定其他 tag 或快照：

```bash
docker build --build-arg BASE_IMAGE=ubuntu:noble-20261024.1 -t local/ubuntu-machine .
```

## 下一步

- 启用插件并初始化运行中的容器：[插件](plugins.md)
- 配置 systemd 服务：[服务](services.md)
- 周期性清理：[维护](maintenance.md)
