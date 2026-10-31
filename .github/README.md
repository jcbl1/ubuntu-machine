# Repository metadata

`.github/repository.json` is the source of truth for the repository description, homepage, and topics.

The [`repository-metadata`](workflows/repository-metadata.yml) workflow applies it through the GitHub API when:

- the JSON file changes on `master`
- the workflow itself changes on `master`
- the workflow is started manually (`workflow_dispatch`)

## Required secret

Create a repository secret named `REPO_METADATA_TOKEN`.

The token must be allowed to edit repository settings:

- Fine-grained PAT: repository permission **Administration: Read and write**
- Classic PAT: `repo` scope

`GITHUB_TOKEN` cannot edit repository metadata such as the description or topics, so a separate token is required.

## Workflow

Edit `.github/repository.json`, commit to `master`, and let the workflow apply the change. To apply without a commit, run the workflow manually from the Actions tab.

## Docker Hub metadata

`.github/repository.json` also contains a `dockerhub` object:

```json
{
  "dockerhub": {
    "short_description": "systemd-enabled Ubuntu 24.04 base image for Apple container machines",
    "readme": "docs/dockerhub.md"
  }
}
```

The release workflow syncs both values after a successful image push using
[`peter-evans/dockerhub-description`](https://github.com/peter-evans/dockerhub-description).
It uses the existing `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets; the token
must have read/write/delete permission for the repository.

Docker Hub limits the short description to 100 bytes and the full description to
25,000 bytes. A description sync failure is reported but does not block the
GitHub Release.

## Validation

The workflow rejects:

- an empty description or one longer than 350 characters
- a homepage that is not empty and not an `http(s)` URL
- more than 20 topics, duplicate topics, or invalid topic characters
- a `dockerhub.short_description` longer than 100 bytes
- a `dockerhub.readme` path that does not exist

GitHub topic rules: lowercase letters, numbers, and hyphens; keep each topic short.
