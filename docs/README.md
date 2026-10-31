# Documentation

Start here if you want to use or extend the image.

| Document | Contents |
|---|---|
| [Apple container machine](apple-container-machine.md) | Primary use case: create and manage an Apple container machine from this image |
| [Usage](usage.md) | Image tags, pulling and running, local builds |
| [Plugins](plugins.md) | Plugin model, enabling plugins, runner options, full catalog |
| [Services](services.md) | OpenCode server, Telegram bot, and cleanup timers |
| [Configuration](configuration.md) | Secrets, private files, OpenCode V2 config, environment variables |
| [Build and release](releasing.md) | Versioning, release workflow, CI behavior |
| [Maintenance](maintenance.md) | Periodic cleanup scope, timers, and tuning |
| [Docker Hub description](dockerhub.md) | Short user-facing overview for the Docker Hub page |

## Documentation conventions

- Commands assume a checkout of this repository unless stated otherwise.
- `plugins/enabled/` and `plugins/private/` are local-only directories.
- User-level plugins skip automatically when no target user exists (for example, during a build).
