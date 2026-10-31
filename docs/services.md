# systemd services

The image ships with systemd enabled. Runtime plugins can install and enable services for the current target user.

| Unit | Installed by | Purpose |
|---|---|---|
| `opencode-server.service` | `095-opencode-server` | OpenCode V2 background server |
| `opencode-telegram-bot.service` | `160-opencode-telegram-bot` | Telegram bot; depends on the OpenCode server |
| `container-tidy.timer` | `140-container-tidy` | Weekly cleanup |
| `container-tidy-boot.timer` | `140-container-tidy` | Cleanup 15 minutes after boot |

## OpenCode server

`095-opencode-server` writes `/etc/systemd/system/opencode-server.service` and runs:

```text
opencode service start   # ExecStart
opencode service stop    # ExecStop
```

It runs as the target user and prefers `~/.opencode/bin/opencode`, falling back to an `opencode` binary on `PATH`.

The server's port, password, and proxy environment live in `~/.config/opencode/service.json`. This file is runtime state and is not provisioned by the plugin, so secrets do not enter the repository. Configure proxy values with:

```bash
opencode service set env http_proxy  http://HOST:PORT
opencode service set env https_proxy http://HOST:PORT
opencode service set env all_proxy   http://HOST:PORT
```

`ExecStart` is idempotent: OpenCode reuses an already running healthy backend. After upgrading the binary, restart the unit to switch backends:

```bash
sudo systemctl restart opencode-server.service
```

## Telegram bot

`160-opencode-telegram-bot` installs:

- `~/opencode-telegram-bot/run-bot.sh`
- `~/opencode-telegram-bot/.nvmrc`
- `~/.config/opencode-telegram-bot/` for `.env`, settings, and logs
- `/etc/systemd/system/opencode-telegram-bot.service`

The unit runs `run-bot.sh` as the target user and restarts on failure. It is enabled and started only when `~/.config/opencode-telegram-bot/.env` exists, which avoids a restart loop before credentials are configured. The `.env` file is normally provisioned by `080-private` from `plugins/private/opencode-telegram-bot.env`.

The launcher uses `proxychains4` (from `045-proxychains`) and nvm (from `100-nvm`).

## Cleanup timers

`140-container-tidy` installs two independent timers:

- `container-tidy.timer` — every Sunday at 06:30 (`Persistent=true`)
- `container-tidy-boot.timer` — 15 minutes after boot

Both trigger `container-tidy.target`, which starts the user-level and root-level cleanup services. See [Maintenance](maintenance.md) for scope and configuration.

## Common commands

```bash
systemctl status opencode-server opencode-telegram-bot
systemctl list-timers 'container-tidy*'
sudo journalctl -u opencode-telegram-bot -n 100
sudo systemctl restart opencode-server.service
```

`container-tidy-boot.timer` shows `NEXT=-` after it has fired. That is expected: it is a one-shot boot timer. The weekly schedule is handled by `container-tidy.timer`.
