# 维护与清理

`140-container-tidy` 安装清理脚本、配置和两个 systemd timer，用于回收空间，同时避免删除项目数据。

## 调度

- `container-tidy.timer`：每周日 06:30，`Persistent=true`
- `container-tidy-boot.timer`：开机 15 分钟后

两者都触发 `container-tidy.target`，并行启动用户级和 root 级清理 service。两个 service 的清理对象互不重叠。

两个 timer 是刻意分开的：在同一个 timer 中混用 `OnCalendar` 和 `OnBootSec`，会导致 systemd 255 在开机触发后不再重排每周任务。

## 清理范围

| 对象 | 门槛 | 运行身份 |
|---|---|---|
| `/tmp/.*.so`（Bun/编译临时产物） | 超过 1 天 | 普通用户 |
| `/tmp/opencode/*` 子项 | 超过 7 天 | 普通用户 |
| `/tmp/systemd-private-*` 目录 | 超过 7 天 | root |
| journald | vacuum 至 50M / 14d | root |
| `/var/cache/apt`（不动 `/var/lib/apt/lists`） | — | root |
| `USER_CACHES` 中列出的 `~/.cache/` 子目录 | — | 普通用户 |

永不触碰：

- `/Users`（宿主机绑定挂载）
- `~/.local/share/opencode/`（会话数据库）
- `~/go`、`~/.rustup`、`~/.opencode`
- 其他用户属主的文件

## 配置

`/etc/default/container-tidy`：

| 变量 | 默认 | 含义 |
|---|---|---|
| `TMP_AGE_DAYS` | 1 | `/tmp` 下 `.so` 产物保留天数 |
| `PROJECT_TMP_AGE_DAYS` | 7 | `/tmp/opencode` 子项保留天数 |
| `STALE_PRIVATE_AGE_DAYS` | 7 | `systemd-private-*` 目录保留天数 |
| `JOURNAL_VACUUM_SIZE` / `JOURNAL_VACUUM_AGE` | 50M / 14d | journald vacuum 阈值 |
| `USER_CACHES` | `pip go-build node` | 要清空的 `~/.cache/` 子目录名 |
| `APT_CLEAN` | `yes` | 是否执行 `apt-get clean` |
| `DRY_RUN` | `0` | 设为 `1` 时只报告不删除 |

`USER_CACHES` 的值是 `~/.cache/` 下的目录名，应按实际使用的运行时调整（例如 `uv`、`pnpm`）。

修改配置后：

```bash
sudo systemctl restart container-tidy.timer container-tidy-boot.timer
```

## 常用命令

```bash
systemctl cat container-tidy.timer container-tidy-boot.timer
systemctl list-timers 'container-tidy*'
sudo journalctl -t container-tidy-user -t container-tidy-root
sudo systemctl start container-tidy.target
sudo systemctl disable --now container-tidy.timer container-tidy-boot.timer
```

`container-tidy-boot.timer` 触发后 `NEXT=-` 属正常现象，它是一次性开机 timer。

service 有意不加 `PrivateTmp`（会清理隔离的 `/tmp`）和 `ProtectHome=read-only`（会阻止删除缓存）。加固仅限 `NoNewPrivileges`、`Nice=19`、`IOSchedulingClass=idle`。

完整文档也会安装到镜像内：`/usr/share/doc/container-tidy/README.md`。
