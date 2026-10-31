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

## Validation

The workflow rejects:

- an empty description or one longer than 350 characters
- a homepage that is not empty and not an `http(s)` URL
- more than 20 topics, duplicate topics, or invalid topic characters

GitHub topic rules: lowercase letters, numbers, and hyphens; keep each topic short.
