# Configuration, secrets, and environment variables

## Secrets and private files

Private files live in `plugins/private/`, which is ignored by git and excluded from the Docker build context.

| Source | Destination | Mode |
|---|---|---|
| `plugins/private/gitconfig` | `~/.gitconfig` | 644 |
| `plugins/private/authorized_keys` | `~/.ssh/authorized_keys` | 600 (`.ssh` is 700) |
| `plugins/private/opencode-telegram-bot.env` | `~/.config/opencode-telegram-bot/.env` | 600 |

`080-private` skips any file that is missing. It never touches SSH private keys or OpenCode credentials.

OpenCode credentials created by `opencode auth login` are not part of this repository.

## OpenCode configuration

`090-opencode` deploys `~/.config/opencode/opencode.jsonc`, `cli.json`, and `opencode-notifier.json` in the native OpenCode V2 format:

- MCP servers are under `mcp.servers`
- A configured server is disabled with `disabled: true` (not `enabled: false`)
- Permissions use an ordered `permissions` array with `shell`, `webfetch`, and `websearch` actions
- Web search is configured with the `websearch` object

The following are runtime state (not fully managed by the plugin):

- `~/.config/opencode/service.json` (server hostname/port, password, proxy environment; optionally seeded by `080-private` from `plugins/private/opencode-service.json`)
- session data under `~/.local/share/opencode/`
- notifier state files

## Environment variables

| Variable | Used by | Effect |
|---|---|---|
| `PROXY_HOST`, `PROXY_PORT` | `045-proxychains`, zsh `pc` alias | Host proxy address; default `192.168.64.1:20121` |
| `UV_VERSION` | `155-uv` | Install a specific uv version instead of latest |
| `YAZI_VERSION` | `060-yazi` | Pin a yazi release tag instead of latest |
| `INSTALL_TAURI_CLI` | `110-rust` | Set to `0` to skip the slow tauri-cli build |
| `TELEGRAM_BOT_NODE_VERSION` | `160-opencode-telegram-bot` | Node version used by the bot (default `v22.23.2`) |
| `SWAPFILE_SIZE` | `170-swapfile` | Swapfile size for a container machine (default `4G`; e.g. `512M`, `8G`) |
| `SWAPFILE_PATH` | `170-swapfile` | Swapfile path (default `/swapfile`); must be on an ext4/xfs filesystem, not `/Users` |
| `SWAPFILE_DRY_RUN` | `170-swapfile` | Set to `1` to print the planned actions without changing anything |
| `http_proxy`, `https_proxy`, `all_proxy` | `045`, downloads, package managers | Standard proxy variables; `run-plugins --proxy` exports all three |

`170-swapfile` installs `machine-swapfile.service` for boot-time activation. Do not use `/etc/fstab` for swap in a container machine: systemd treats the machine as a container and ignores fstab swap entries.

`run-plugins` also supports `--target-user` for containers where the default user detection is not appropriate.

## Ignored local state

- `plugins/enabled/` — local symlinks that select which plugins run
- `plugins/private/` — local secrets
- `NOTES.md`, `NOTES.*.md` — local implementation notes

## Related documents

- [Plugins](plugins.md)
- [Services](services.md)
- [Usage](usage.md)
