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
3. Builds an `amd64` image from that snapshot and scans it with Trivy
4. Builds `linux/amd64,linux/arm64` from that snapshot
5. Pushes `latest`, `vX.Y`, `vX.Y-noble`, `vX.Y-24.04`, and `vX.Y-nobleYYYYMMDD[.N]`
6. Creates a GitHub Release with generated notes
7. Syncs the Docker Hub short description and overview from `.github/repository.json` and `docs/dockerhub.md`

## CI behavior

- Pull requests validate an `amd64` build only
- Pushes to `master` validate `amd64` and `arm64` builds without pushing
- Tag pushes run the release workflow
- Pull requests, `master` pushes, and a weekly schedule run a Trivy image scan
- The release workflow refuses a version older than the latest release, protecting `latest` from accidental downgrades

## Security scanning

[Trivy](https://trivy.dev/) scans the built image for OS/library vulnerabilities and embedded secrets:

- `security-scan` runs on pull requests, pushes to `master`, and weekly on a schedule
- The release workflow builds and scans the resolved snapshot before pushing anything
- Only `HIGH` and `CRITICAL` vulnerabilities with an available fix are reported (`ignore-unfixed`); the secret scanner also flags private keys and other credentials
- SSH host keys are generated at first boot and never baked into the image
- Both workflows upload SARIF to the repository's **Security → Code scanning** tab (fork PRs keep the report as a workflow artifact), and the release workflow also writes the table report to the job summary
- The pre-push scan covers `amd64`; the release also publishes `arm64`, which uses the same Ubuntu source package versions

The scans currently run in report mode: the table scan uses `exit-code: '0'` and is the only step that owns the gate. The SARIF scan always runs after a successful build and stays non-gating, so results are still published when a future `exit-code: '1'` blocks the job. After reviewing the baseline, set the table steps in `security-scan.yml` and `release.yml` to `exit-code: '1'` to make fixable high-severity findings block merges and releases.

If a finding is accepted, add a `.trivyignore.yaml` file with the justification and then pass it to both scans via the `trivyignores` input. The file must exist before the input is added, otherwise Trivy fails.

## Repository metadata

Description, homepage, and topics are maintained in `.github/repository.json` and applied by the `repository-metadata` workflow. The workflow requires a `REPO_METADATA_TOKEN` secret with repository administration write access; see [.github/repository-metadata.md](../.github/repository-metadata.md).

## Requirements

- Repository variable `DOCKERHUB_IMAGE` (for example `jcbl1/ubuntu-machine`)
- Secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`

Do not move or delete a published tag. Publish a new version instead.
