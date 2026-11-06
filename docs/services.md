# systemd services

The image ships with systemd enabled. Runtime plugins can install and enable services for the current target user.

| Unit | Installed by | Purpose |
|---|---|---|
| `ssh-host-keys.service` | Base image | Generate SSH host keys on first boot |
| `opencode-server.service` | `095-opencode-server` | OpenCode V2 background server |
| `opencode-telegram-bot.service` | `160-opencode-telegram-bot` | Telegram bot; depends on the OpenCode server |
| `container-tidy.timer` | `140-container-tidy` | Weekly cleanup |
| `container-tidy-boot.timer` | `140-container-tidy` | Cleanup 15 minutes after boot |

## SSH host keys

`ssh-host-keys.service` is part of the base image. It runs `ssh-keygen -A` before `ssh.service` and creates the host keys on first boot, so every machine gets a unique set. The image itself contains no host keys: the build removes the package-generated keys in the same layer that installs `openssh-server`, so they cannot be recovered from image layers.

Machines created from an older image may still contain the previously baked keys. Rotate them with:

```bash
sudo rm -f /etc/ssh/ssh_host_*
sudo systemctl restart ssh-host-keys.service ssh.service
```

## OpenCode server

`095-opencode-server` writes `/etc/systemd/system/opencode-server.service` and runs:

```text
opencode service start   # ExecStart
opencode service stop    # ExecStop
```

It runs as the target user and prefers `~/.opencode/bin/opencode`, falling back to an `opencode` binary on `PATH`.

The server's port, hostname, password, and proxy environment live in `~/.config/opencode/service.json`. `080-private` optionally provisions this file from `plugins/private/opencode-service.json` (600, not in git), so the same local API password and proxy settings apply to every container. Without that file, OpenCode generates a random password on first start. It listens on `127.0.0.1:49374` by default; set `hostname` to `0.0.0.0` to accept connections from the host (the API still requires the password). Configure the managed values with:

```bash
opencode service set hostname 0.0.0.0
opencode service set port 49374
opencode service set env HTTP_PROXY  http://HOST:PORT
opencode service set env HTTPS_PROXY http://HOST:PORT
opencode service set env NO_PROXY    localhost,127.0.0.1,::1
```

`NO_PROXY` must include the loopback addresses: the CLI talks to the background server over local HTTP. Changing any of these values stops the running service, so start it again afterwards.

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

The launcher uses nvm (from `100-nvm`) to install and select the pinned Node version. Telegram traffic goes through the bot's own `TELEGRAM_PROXY_URL` setting in `.env`; the launcher no longer wraps the process in `proxychains4`, because that also proxied requests to the local OpenCode API.

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
