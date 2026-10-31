# Build and release

## Local build

```bash
docker build -t local/ubuntu-machine .
```

The default base image is `ubuntu:24.04`. Pin a different tag or snapshot with `BASE_IMAGE`:

```bash
docker build --build-arg BASE_IMAGE=ubuntu:noble-20261024.1 -t local/ubuntu-machine .
```

The build context excludes `.git`, `plugins/private/`, and local `NOTES` files. `plugins/enabled/` is kept so local builds can use the current symlink selection.

## Version tags

Versions come only from git tags in the form `vX.Y`. A release publishes these tags with the same digest:

| Tag | Meaning |
|---|---|
| `latest` | Latest stable release |
| `vX.Y` | Project version |
| `vX.Y-noble` | Project version + Ubuntu codename |
| `vX.Y-24.04` | Project version + Ubuntu version |
| `vX.Y-nobleYYYYMMDD[.N]` | Project version + base image snapshot |

## Release process

After the changes are on `master`:

```bash
git tag v1.2
git push origin v1.2
```

The `release` workflow then:

1. Validates the tag format and checks that the commit is on `master`
2. Resolves the Ubuntu snapshot tag matching the `BASE_IMAGE` digest
3. Builds `linux/amd64,linux/arm64` from that snapshot
4. Pushes `latest`, `vX.Y`, `vX.Y-noble`, `vX.Y-24.04`, and `vX.Y-nobleYYYYMMDD[.N]`
5. Creates a GitHub Release with generated notes
6. Syncs the Docker Hub short description and overview from `.github/repository.json` and `docs/dockerhub.md`

## CI behavior

- Pull requests validate an `amd64` build only
- Pushes to `master` validate `amd64` and `arm64` builds without pushing
- Tag pushes run the release workflow
- The release workflow refuses a version older than the latest release, protecting `latest` from accidental downgrades

## Repository metadata

Description, homepage, and topics are maintained in `.github/repository.json` and applied by the `repository-metadata` workflow. The workflow requires a `REPO_METADATA_TOKEN` secret with repository administration write access; see [.github/README.md](../.github/README.md).

## Requirements

- Repository variable `DOCKERHUB_IMAGE` (for example `jcbl1/ubuntu-machine`)
- Secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`

Do not move or delete a published tag. Publish a new version instead.
