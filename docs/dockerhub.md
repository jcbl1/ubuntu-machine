# ubuntu-machine

A systemd-enabled Ubuntu 24.04 image built primarily as a base image for [Apple container](https://github.com/apple/container) machines. It is OCI-compatible and also runs in Docker and other runtimes.

## Apple container machine

```bash
container machine create jcbl1/ubuntu-machine:latest --name ubuntu
container machine set-default ubuntu
container machine run -n ubuntu
```

The machine gets your macOS username, UID/GID, and home directory mapped in, with systemd as PID 1 and passwordless sudo.

## What's included

- Ubuntu 24.04 with systemd, dbus, sshd, and sudo
- A Bash plugin runner used both at build time and inside a running machine
- Optional plugins for OpenCode, a Telegram bot, Java 17, Go, Rust, Node.js, uv, yazi, tmux, and common CLI tools
- Versioned images built from pinned Ubuntu snapshots

## Pull

```bash
docker pull jcbl1/ubuntu-machine:latest
```

## Other runtimes

```bash
docker run -d --name ubuntu-machine --hostname ubuntu-machine \
  --privileged -p 2222:22 \
  jcbl1/ubuntu-machine:latest
```

The image runs systemd as PID 1 and needs a systemd-capable runtime. `--privileged` is the simplest option; use narrower capabilities where possible.

## Links

- Source and documentation: <https://github.com/jcbl1/ubuntu-machine>
- Image tags: <https://hub.docker.com/r/jcbl1/ubuntu-machine/tags>

No credentials or private keys are baked into the image. Only create container machines from images you trust.
