# Usage

For Apple container machines, see [Apple container machine](apple-container-machine.md). This page covers image tags and generic OCI/Docker usage.

## Requirements

The image runs `systemd` as PID 1. Use a runtime that can run a systemd container with cgroups available. The examples use `--privileged` for simplicity; production deployments should use the narrowest capabilities and mounts that work for their runtime.

## Image tags

| Tag | Meaning |
|---|---|
| `latest` | Latest stable release |
| `vX.Y` | Project version |
| `vX.Y-noble` | Project version + Ubuntu codename |
| `vX.Y-24.04` | Project version + Ubuntu version |
| `vX.Y-nobleYYYYMMDD[.N]` | Project version + Ubuntu snapshot used at build time |

All tags from one release point to the same image digest. For example, a `v1.2` release publishes:

```bash
docker pull jcbl1/ubuntu-machine:latest
docker pull jcbl1/ubuntu-machine:v1.2
docker pull jcbl1/ubuntu-machine:v1.2-noble
docker pull jcbl1/ubuntu-machine:v1.2-24.04
docker pull jcbl1/ubuntu-machine:v1.2-noble20261024.1
```

## Run

Generic Docker / OCI runtime with systemd:

```bash
docker run -d --name ubuntu-machine --hostname ubuntu-machine \
  --privileged -p 2222:22 \
  jcbl1/ubuntu-machine:latest

docker exec -it ubuntu-machine systemctl status
```

The base image contains `openssh-server` but no credentials. To log in over SSH, provision an `authorized_keys` file through the `080-private` plugin (see [Configuration](configuration.md)) or create users and keys yourself.

SSH host keys are not baked into the image. `ssh-host-keys.service` runs `ssh-keygen -A` before `ssh.service` on first boot, so every machine gets a unique set.

## Build locally

```bash
docker build -t local/ubuntu-machine .
```

The default base image is `ubuntu:24.04`. Pin a different tag or snapshot with `BASE_IMAGE`:

```bash
docker build --build-arg BASE_IMAGE=ubuntu:noble-20261024.1 -t local/ubuntu-machine .
```

## Next steps

- Enable plugins and initialize a running container: [Plugins](plugins.md)
- Configure services: [Services](services.md)
- Keep the container tidy: [Maintenance](maintenance.md)
