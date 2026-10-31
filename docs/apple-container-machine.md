# Apple container machine

This image's primary purpose is to serve as a base image for [Apple container](https://github.com/apple/container) machines: persistent Linux environments that run as lightweight VMs on Apple silicon and integrate with macOS.

## What a container machine gives you

- A persistent Linux environment with the image's own init system (this image uses systemd)
- Your macOS username, UID/GID, and Linux home directory created automatically
- Your macOS home directory mounted read-write at the same path (`/Users/<username>`)
- A shell that starts in the equivalent directory when you run it from under your home
- Passwordless `sudo` for the mapped user
- State that survives `container machine stop` and later restarts

## Requirements

- An Apple silicon Mac
- A macOS version supported by your `container` release (see the [container README](https://github.com/apple/container#requirements))
- `container` installed and its system service running:

```bash
container system start
```

## Create and use a machine

```bash
container machine create jcbl1/ubuntu-machine:latest --name ubuntu
container machine set-default ubuntu
container machine run -n ubuntu
```

Run a single command:

```bash
container machine run -n ubuntu uname -a
```

The `machine` subcommand has an alias `m`:

```bash
m run -n ubuntu
```

Manage the machine:

```bash
container machine ls
container machine inspect ubuntu
container machine stop ubuntu
container machine rm ubuntu
```

## User and home mapping

`container machine` provisions the guest account on first boot. By default it matches your macOS account:

- Same username and UID/GID
- Linux home directory under `/home/<username>`
- Passwordless sudo via `/etc/sudoers.d/<username>`
- macOS home mounted at `/Users/<username>`, with your macOS permissions

When you run `container machine run` from a directory under your macOS home, the Linux process starts in the equivalent directory. This means a repository checkout on the Mac is directly available inside the machine, and you can run the plugin pool without copying files:

```bash
cd /Users/<you>/path/to/ubuntu-machine
sudo bash plugins/bin/run-plugins
```

Override the account at creation time if needed:

```bash
container machine create --user devuser --uid 1500 --gid 1600 \
  jcbl1/ubuntu-machine:latest --name ubuntu
```

## Plugins in a container machine

Plugin scripts are intentionally not baked into the image; the image ships the runner and you run plugins from a checkout. A typical first boot looks like:

```bash
container machine run -n ubuntu -- bash -lc '
  cd /Users/<you>/path/to/ubuntu-machine &&
  sudo bash plugins/bin/run-plugins --dry-run
'
```

Remove `--dry-run` to apply. See [Plugins](plugins.md) for the catalog and options.

## Build a local image

```bash
container build -t local/ubuntu-machine:latest .
container machine create local/ubuntu-machine:latest --name ubuntu
```

The Dockerfile follows Apple's container-machine image requirements: systemd is installed, `/sbin/init` is present, and the base machine utilities needed for user provisioning are included.

## Security

Apple's documentation warns that a container machine is much closer to running software directly on your Mac than to running a regular container:

- It runs with all Linux capabilities
- Your home directory is mounted read-write
- Your SSH agent is forwarded
- The image's init process runs as root

Only create container machines from images you trust. Review the Dockerfile and plugins before creating a machine from a custom build.

## Related documents

- [Usage](usage.md)
- [Plugins](plugins.md)
- [Services](services.md)
