# ubuntu-machine

[中文文档](docs/zh/README.md)

A systemd-enabled Ubuntu 24.04 image built primarily as a **base image for [Apple container](https://github.com/apple/container) machines**, with a small plugin system for provisioning software and user configuration.

The image is OCI-compatible, so it also runs in Docker and other container runtimes. Published on Docker Hub as [`jcbl1/ubuntu-machine`](https://hub.docker.com/r/jcbl1/ubuntu-machine).

## Features

- Ubuntu 24.04 with systemd as PID 1, plus dbus, sshd, and sudo
- Designed for Apple container machines: persistent Linux environment with your macOS user and home directory mapped in
- Plugins are plain Bash scripts, enabled with symlinks and executed in filename order
- The same plugin pool runs at build time and inside a running machine
- Optional integrations for OpenCode, a Telegram bot, Java, Go, Rust, Node.js (nvm), uv, yazi, tmux, and more

## Quick start

Create an Apple container machine:

```bash
container machine create jcbl1/ubuntu-machine:latest --name ubuntu
container machine set-default ubuntu
container machine run -n ubuntu
```

Or use it as a regular Docker container:

```bash
docker run -d --name ubuntu-machine --hostname ubuntu-machine \
  --privileged -p 2222:22 \
  jcbl1/ubuntu-machine:latest
```

Build locally:

```bash
container build -t local/ubuntu-machine:latest .
# or: docker build -t local/ubuntu-machine .
```

## Documentation

- [Apple container machine](docs/apple-container-machine.md)
- [Usage, image tags, and other runtimes](docs/usage.md)
- [Plugin system and plugin catalog](docs/plugins.md)
- [systemd services](docs/services.md)
- [Configuration, secrets, and environment variables](docs/configuration.md)
- [Build and release](docs/releasing.md)
- [Maintenance and cleanup](docs/maintenance.md)
- [Docker Hub description](docs/dockerhub.md)

## Repository layout

```text
.
├── Dockerfile
├── plugins/
│   ├── bin/run-plugins
│   ├── available/
│   ├── enabled/          # local symlinks, not tracked
│   └── private/          # local secrets, not tracked
└── docs/
```

## License

MIT
