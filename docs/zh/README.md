# 文档

[English documentation](../README.md)

| 文档 | 内容 |
|---|---|
| [Apple container machine](apple-container-machine.md) | 作为 Apple container machine 基础镜像的使用方式 |
| [使用](usage.md) | 镜像 tag、拉取与运行、本地构建 |
| [插件](plugins.md) | 插件模型、启用方式、执行器参数、完整目录 |
| [服务](services.md) | OpenCode server、Telegram bot、清理定时器 |
| [配置](configuration.md) | 密钥、私密文件、OpenCode V2 配置、环境变量 |
| [构建与发版](releasing.md) | 版本规则、发版流程、CI 行为 |
| [维护](maintenance.md) | 周期性清理范围、定时器、调优 |

## 约定

- 命令默认在仓库根目录执行，除非另有说明。
- `plugins/enabled/` 与 `plugins/private/` 是本地目录，不入库。
- 无目标用户时（例如构建期），用户级插件会自动跳过。
