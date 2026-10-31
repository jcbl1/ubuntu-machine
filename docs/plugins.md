# Plugins

Plugins are plain Bash scripts. The runner executes every enabled plugin in lexicographic filename order, so numeric prefixes control ordering (`010-`, `020-`, ...).

The image ships the runner (`/usr/local/sbin/run-plugins`); plugin scripts stay in the repository checkout. Run `plugins/bin/run-plugins` from the checkout, which is directly available under the mounted macOS home in an Apple container machine.

## Layout

```text
plugins/
├── bin/run-plugins        # shared runner (build time and runtime)
├── available/             # all plugins
├── enabled/               # symlinks only; enabled = ln -s, disabled = rm
└── private/               # local secrets, provisioned by 080-private
```

`plugins/enabled/` and `plugins/private/` are ignored by git.

## Enable or disable a plugin

```bash
ln -s ../available/050-my-plugin plugins/enabled/050-my-plugin   # enable
rm plugins/enabled/050-my-plugin                                 # disable
```

The `enabled/` directory is local state, not part of the repository.

## Plugin contract

- Plain Bash, executed with `bash` in filename order
- Self-contained: install required packages yourself, then clean up
  (`apt-get clean && rm -rf /var/lib/apt/lists/*`)
- Non-interactive: the runner exports `DEBIAN_FRONTEND=noninteractive`
- Never write into the plugin directory; at build time it is mounted read-only
- Idempotent: safe to run repeatedly
- User-level plugins check `TARGET_USER` and skip when it is empty (build time)

The runner exports:

| Variable | Meaning |
|---|---|
| `PLUGIN_NAME` | Basename of the plugin script |
| `DEBIAN_FRONTEND` | `noninteractive` |
| `TARGET_USER` | Target user for user-level configuration; empty when none can be resolved |
| `PLUGIN_ROOT` | `plugins/` directory when running from the repository layout |

## Runner options

```bash
sudo bash plugins/bin/run-plugins                    # run all enabled plugins
sudo bash plugins/bin/run-plugins --proxy URL        # export http(s)_proxy/all_proxy
sudo bash plugins/bin/run-plugins --dry-run          # list plugins without running
sudo bash plugins/bin/run-plugins --enabled DIR      # use another enabled directory
sudo bash plugins/bin/run-plugins --target-user USER # set the target user
```

`TARGET_USER` resolution order: `--target-user`, `$TARGET_USER`, `$SUDO_USER`, then the first non-root user whose home is under `/home/`. The runner exits non-zero if any plugin fails.

## Run a subset

```bash
mkdir -p /tmp/plugins
ln -s "$PWD/plugins/available/150-java" /tmp/plugins/150-java
ln -s "$PWD/plugins/available/155-uv" /tmp/plugins/155-uv
sudo bash plugins/bin/run-plugins /tmp/plugins
```

## Plugin catalog

| Plugin | What it does | Phase |
|---|---|---|
| `010-example` | Example: installs htop and writes `/etc/motd` | Build |
| `020-codex` | OpenAI Codex CLI (official installer, system-wide) | Build |
| `020-opencode` | opencode system-wide install in `/usr/local/bin`; `090-opencode` is the usual choice now | Build |
| `030-cli-tools` | git, zsh, tmux, fzf, ripgrep, fd, bat, btop, htop, ncdu, lsof, rsync, vim, strace, unzip, file, less, pandoc | Build/runtime |
| `035-build-essential` | make, gcc, g++, libc-dev | Build/runtime |
| `040-zsh` | oh-my-zsh, zsh-autosuggestions, `.zshrc`, `all-in-one.zsh`, bash/profile environment blocks | Runtime |
| `045-proxychains` | proxychains4 and `/etc/proxychains4.conf` pointing at the host proxy | Build/runtime |
| `050-tmux` | `~/.tmux.conf`, tpm, and headless plugin installation | Runtime |
| `060-yazi` | yazi/ya binaries from GitHub releases and `yazi.toml` | Runtime |
| `070-dotfiles` | btop config, ncdu config, and `~/ncdu-exclude.txt` | Runtime |
| `080-private` | Installs gitconfig, authorized_keys, and bot `.env` from `private/` | Runtime |
| `090-opencode` | OpenCode V2 user config (`opencode.jsonc`, `cli.json`, notifier) | Runtime |
| `095-opencode-server` | `opencode-server.service` for the OpenCode background server | Runtime |
| `100-nvm` | nvm (no Node version preinstalled) | Runtime |
| `110-rust` | rustup + stable; optionally compiles tauri-cli (slow) | Runtime |
| `120-go` | golang-go from Ubuntu 24.04 | Build/runtime |
| `130-tauri-deps` | Tauri/GUI build dependencies (gtk, webkit, mingw, etc.; large) | Build/runtime |
| `140-container-tidy` | Cleanup scripts plus weekly and boot systemd timers | Build/runtime |
| `150-java` | Eclipse Temurin 17 JDK from the Adoptium apt repository | Build/runtime |
| `155-uv` | uv in `~/.local/bin` | Runtime |
| `160-opencode-telegram-bot` | Telegram bot launcher and `opencode-telegram-bot.service` | Runtime |

## Build-time behavior

At build time there is no target user, so user-level plugins (`040`, `050`, `060`, `070`, `080`, `090`, `095`, `100`, `110`, `155`, `160`) skip automatically. They run when `run-plugins` is executed inside a created container.

## Related documents

- Service setup: [Services](services.md)
- Secrets and environment knobs: [Configuration](configuration.md)
