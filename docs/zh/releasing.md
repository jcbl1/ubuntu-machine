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
3. 以该快照构建 `amd64` 镜像并用 Trivy 扫描
4. 以该快照构建 `linux/amd64,linux/arm64`
5. 推送 `latest`、`vX.Y`、`vX.Y-noble`、`vX.Y-24.04`、`vX.Y-nobleYYYYMMDD[.N]`
6. 创建 GitHub Release（自动生成 changelog）
7. 从 `.github/repository.json` 和 `docs/dockerhub.md` 同步 Docker Hub 短描述与完整描述

## CI 行为

- Pull request 只验证 `amd64` 构建
- 推送 `master` 验证 `amd64` 与 `arm64`，不推送镜像
- 推送 tag 时执行发版 workflow
- Pull request、推送 `master` 以及每周定时任务会运行 Trivy 镜像扫描
- 发版 workflow 拒绝比当前最新版本更旧的版本号，避免 `latest` 被误回退

## 安全扫描

[Trivy](https://trivy.dev/) 会扫描构建出的镜像中的系统包/库漏洞和内嵌密钥：

- `security-scan` 在 pull request、推送 `master` 和每周定时任务中运行
- 发版 workflow 在推送任何镜像前，先构建并扫描解析后的快照
- 只报告存在修复版本的 `HIGH`、`CRITICAL` 漏洞（`ignore-unfixed`）；secret scanner 还会标记私钥和其他凭据
- SSH host key 在首次启动时生成，不会固化进镜像
- 两个 workflow 都会把 SARIF 结果上传到仓库的 **Security → Code scanning** 页面（fork PR 则以 workflow artifact 形式保留报告），发版 workflow 还会把 table 报告写入 job summary
- 发版前的扫描只覆盖 `amd64`；发布产物还包含 `arm64`，但两者使用相同的 Ubuntu 源码包版本

当前扫描运行在报告模式：table 扫描使用 `exit-code: '0'`，并且只有该步骤承担门禁职责。SARIF 扫描在构建成功后总是运行且不参与门禁，因此将来把 `exit-code` 改为 `'1'` 阻断任务时，报告仍会正常生成和上传。确认基线后，把 `security-scan.yml` 和 `release.yml` 中 table 扫描步骤的 `exit-code` 改为 `'1'`，即可让可修复的高危漏洞阻止合并与发版。

如果需要接受某个风险，先新增 `.trivyignore.yaml` 记录原因，再通过 `trivyignores` 输入传给两个扫描。文件必须先存在，否则 Trivy 会报错。

## 仓库 metadata

描述、主页和 topics 由 `.github/repository.json` 维护，并通过 `repository-metadata` workflow 自动应用。workflow 需要 `REPO_METADATA_TOKEN` secret，且 token 具备仓库 Administration 写权限；详见 [.github/repository-metadata.md](../../.github/repository-metadata.md)。

## 要求

- 仓库变量 `DOCKERHUB_IMAGE`（如 `jcbl1/ubuntu-machine`）
- secrets `DOCKERHUB_USERNAME`、`DOCKERHUB_TOKEN`

已推送的 tag 不要移动或删除；修复问题请发布新版本。
