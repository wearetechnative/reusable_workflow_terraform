# reusable_workflow_terraform

Shared GitHub Actions workflows for the Terraform module repositories in this
organisation. Consumers call these instead of copying the steps, so a tool
version or an action pin is changed here once rather than in 53 repositories.

## Workflows

### `lint.yml` — checks `lint / tflint` and `lint / validate`

| Input           | Type    | Default | Meaning                                                      |
| --------------- | ------- | ------- | ------------------------------------------------------------ |
| `strict`        | boolean | `false` | Fail the build on TFLint findings                            |
| `skip-validate` | boolean | `false` | Skip `terraform validate` entirely                           |

The job also refuses `git@github.com:` module sources. The validate job rewrites
those URLs so a runner can fetch them, but a module that needs that rewrite only
builds inside this CI - not on a developer machine without a key, and not for a
consumer. Use `git::https://github.com/...`. Like a TFLint finding, this fails
the build only when `strict` is set.

TFLint runs with `--recursive`. Several modules keep all their `.tf` files in
subdirectories, where a root-only run passes while checking nothing.

A TFLint **finding** (exit 2) fails the build only when `strict` is set. A TFLint
**error** (exit 1) always fails, whatever `strict` says — that is the class of
failure that stayed invisible for years behind a scanner which could not parse
the code, and it must never be silenceable.

Set `skip-validate: true` for modules declaring `configuration_aliases`. As a
root module there is no aliased provider configured, so `terraform validate`
reports `missing provider` by design rather than because anything is wrong.

### `security-scan.yml` — check `security-scan / trivy`

| Input      | Type   | Default | Meaning                                                    |
| ---------- | ------ | ------- | ---------------------------------------------------------- |
| `block-on` | string | `''`    | Trivy severities that fail the build, e.g. `HIGH,CRITICAL` |

Unset, every severity is reported and the build always passes. That is the
correct setting for a repository whose findings have not been cleaned up yet —
turn it on per repository once that repository is clean, not organisation-wide.

## Using them

```yaml
# .github/workflows/lint.yaml
name: Lint
on:
  push:
    branches: [main]
  pull_request:
jobs:
  lint:
    uses: wearetechnative/reusable_workflow_terraform/.github/workflows/lint.yml@v1
```

```yaml
# .github/workflows/security-scan.yaml
name: Security scan
on:
  push:
    branches: [main]
  pull_request:
jobs:
  security-scan:
    uses: wearetechnative/reusable_workflow_terraform/.github/workflows/security-scan.yml@v1
    with:
      block-on: HIGH,CRITICAL
```

## Releasing — do not skip this

Consumers pin `@v1`, a **moving tag**. Merging to `main` changes nothing for
them; moving the tag is what ships.

```bash
git tag -f v1 <merge-sha>
git push -f origin v1
```

This is deliberate: it separates *merged* from *live*, so a change can be tried
against a single repository before every consumer receives it. The cost is that
**a merge without a tag move ships nothing**, and no one will notice — every
consumer silently keeps running the previous code.

Treat the tag move as part of the merge, not as a follow-up.

There is no `v2` and there should never need to be one. Behaviour that differs
per repository is an input, not a version.

## Running the same checks locally

```bash
nix run nixpkgs/nixos-unstable#tflint -- --recursive -f compact
nix run nixpkgs/nixos-unstable#trivy  -- config --severity HIGH,CRITICAL .
terraform init -backend=false && terraform validate
```

Two caveats that have already cost time:

- `nixpkgs-unstable` and CI do not run identical Trivy versions. That difference
  is the first suspect for any local/CI discrepancy.
- `TF_PLUGIN_CACHE_DIR` has no locking. Sharing one cache across parallel
  `terraform init` runs corrupts it and produces convincing but false
  "Failed to install provider" errors. Run sequentially, or not at all.

Use `tfswitch <version>` when a module's `required_version` exceeds the
terraform you have installed.
