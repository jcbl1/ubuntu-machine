# Maintenance and cleanup

`140-container-tidy` installs cleanup scripts, configuration, and two systemd timers. It is designed to reclaim space without deleting project data.

## Schedule

- `container-tidy.timer` — every Sunday at 06:30, with `Persistent=true`
- `container-tidy-boot.timer` — 15 minutes after boot

Both trigger `container-tidy.target`, which starts a user-level cleanup service and a root-level cleanup service in parallel. The two services touch disjoint paths.

The timers are intentionally separate. Combining `OnCalendar` and `OnBootSec` in one timer caused systemd 255 to stop re-arming the weekly schedule after the boot trigger.

## Cleanup scope

| Target | Threshold | Runs as |
|---|---|---|
| `/tmp/.*.so` (Bun/build temporary objects) | older than 1 day | user |
| `/tmp/opencode/*` entries | older than 7 days | user |
| `/tmp/systemd-private-*` directories | older than 7 days | root |
| journald | vacuum to 50M / 14d | root |
| `/var/cache/apt` (does not touch `/var/lib/apt/lists`) | — | root |
| Directories listed in `USER_CACHES` under `~/.cache/` | — | user |
| Paths listed in `USER_CACHE_PATHS` (relative to `$HOME` or absolute) | — | user |

Never touched:

- `/Users` (host bind mount)
- `~/.local/share/opencode/` (session database)
- `~/go`, `~/.rustup`, `~/.opencode`
- `~/.npm/_npx` (the Telegram bot runs from here)
- `~/.cache/ms-playwright` (browser cache; expensive to re-download)
- Files owned by other users

## Configuration

`/etc/default/container-tidy`:

| Variable | Default | Meaning |
|---|---|---|
| `TMP_AGE_DAYS` | 1 | Retention for `/tmp` `.so` files |
| `PROJECT_TMP_AGE_DAYS` | 7 | Retention for `/tmp/opencode` entries |
| `STALE_PRIVATE_AGE_DAYS` | 7 | Retention for `systemd-private-*` directories |
| `JOURNAL_VACUUM_SIZE` / `JOURNAL_VACUUM_AGE` | 50M / 14d | journald vacuum thresholds |
| `USER_CACHES` | `pip go-build node uv pnpm` | Directory names under `~/.cache/` to clear |
| `USER_CACHE_PATHS` | `.npm/_cacache` | Additional paths to clear, relative to `$HOME` or absolute; space-separated |
| `APT_CLEAN` | `yes` | Run `apt-get clean` |
| `DRY_RUN` | `0` | Set to `1` to report without deleting |

`USER_CACHES` values are literal directory names under `~/.cache/`. `USER_CACHE_PATHS` entries are relative to `$HOME` unless they start with `/`. Adjust them to match the runtimes you actually use. `~/.npm/_npx` and `~/.cache/ms-playwright` are deliberately excluded by default.

Precedence: built-in defaults < `/etc/default/container-tidy` < environment variables < command line (`--dry-run`). The scripts read the file on every run, so changes take effect on the next run; only timer schedule changes require a restart.

Preview without deleting anything:

```bash
sudo -u <user> /usr/local/bin/container-tidy-user.sh --dry-run
sudo /usr/local/bin/container-tidy-root.sh --dry-run
```

## Commands

```bash
systemctl cat container-tidy.timer container-tidy-boot.timer
systemctl list-timers 'container-tidy*'
sudo journalctl -t container-tidy-user -t container-tidy-root
sudo systemctl start container-tidy.target
sudo systemctl disable --now container-tidy.timer container-tidy-boot.timer
```

`container-tidy-boot.timer` reports `NEXT=-` after it has fired. This is expected for a one-shot boot timer.

The service units deliberately avoid `PrivateTmp` (it would clean an isolated `/tmp`) and `ProtectHome=read-only` (it would block cache deletion). Hardening is limited to `NoNewPrivileges`, `Nice=19`, and `IOSchedulingClass=idle`.

Full documentation is also installed into the image at `/usr/share/doc/container-tidy/README.md`.
