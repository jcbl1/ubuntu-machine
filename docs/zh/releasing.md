# 构建与发版

## 本地构建

```bash
docker build -t local/ubuntu-machine .
```

默认基础镜像为 `ubuntu:24.04`，可用 `BASE_IMAGE` 指定其他 tag 或快照：

```bash
docker build --build-arg BASE_IMAGE=ubuntu:noble-20261024.1 -t local/ubuntu-machine .
```

构建上下文排除 `.git`、`plugins/private/` 和本地 `NOTES` 文件。保留 `plugins/enabled/`，因此本地构建可以沿用当前软链选择。

## 版本 tag

版本号只来自 git tag，格式为 `vX.Y`。一次发布会产生以下指向同一 digest 的 tag：

| Tag | 说明 |
|---|---|
| `latest` | 最新正式版本 |
| `vX.Y` | 项目版本 |
| `vX.Y-noble` | 项目版本 + Ubuntu codename |
| `vX.Y-24.04` | 项目版本 + Ubuntu 版本号 |
| `vX.Y-nobleYYYYMMDD[.N]` | 项目版本 + 基础镜像快照 |

## 发版流程

确认改动已在 `master` 上后：

```bash
git tag v1.2
git push origin v1.2
```

`release` workflow 会：

1. 校验 tag 格式，并确认该 commit 在 `master` 上
2. 解析 `BASE_IMAGE` digest 对应的 Ubuntu 快照 tag
3. 以该快照构建 `linux/amd64,linux/arm64`
4. 推送 `latest`、`vX.Y`、`vX.Y-noble`、`vX.Y-24.04`、`vX.Y-nobleYYYYMMDD[.N]`
5. 创建 GitHub Release（自动生成 changelog）
6. 从 `.github/repository.json` 和 `docs/dockerhub.md` 同步 Docker Hub 短描述与完整描述

## CI 行为

- Pull request 只验证 `amd64` 构建
- 推送 `master` 验证 `amd64` 与 `arm64`，不推送镜像
- 推送 tag 时执行发版 workflow
- 发版 workflow 拒绝比当前最新版本更旧的版本号，避免 `latest` 被误回退

## 仓库 metadata

描述、主页和 topics 由 `.github/repository.json` 维护，并通过 `repository-metadata` workflow 自动应用。workflow 需要 `REPO_METADATA_TOKEN` secret，且 token 具备仓库 Administration 写权限；详见 [.github/repository-metadata.md](../../.github/repository-metadata.md)。

## 要求

- 仓库变量 `DOCKERHUB_IMAGE`（如 `jcbl1/ubuntu-machine`）
- secrets `DOCKERHUB_USERNAME`、`DOCKERHUB_TOKEN`

已推送的 tag 不要移动或删除；修复问题请发布新版本。
