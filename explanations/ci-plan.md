# GitHub Actions CI Plan

This plan adds a pull-request check for the unified customer-orders OpenAPI contract. The contract contains the pagination, identifier, status, and asynchronous-creation scenarios used in the demo.

## Important: local commit versus CI

For the intentional failing demonstration, the local pre-commit hook may block the commit before the branch can be pushed. That is expected: the hook is doing its job locally, but this demo needs GitHub Actions to display the failed PR check.

Use:

```shell
git commit --no-verify -m "Demo: make order offset mandatory"
```

Then push the branch and open the pull request. Do not run the commit command twice. The PR is intentionally allowed to contain the breaking spec so that CI can report `INCOMPATIBLE`.

## 1. Add the Enterprise license to GitHub

The CI workflow uses `specmatic/enterprise:latest`, so configure the license in GitHub:

1. Open **Settings → Environments**.
2. Create or open the environment named `SPECMATIC_LICENSE_ENV`.
3. Under **Environment secrets**, select **Add secret**.
4. Name it `SPECMATIC_LICENSE`.
5. Paste the contents of the local `license.txt` file.
6. Save the secret.

Do not commit `license.txt`.

## 2. Add the workflow

Create `.github/workflows/bcc.yml` at the repository root.

The workflow:

- runs for pull requests that change specifications or the workflow;
- checks out the full Git history;
- runs the Specmatic Enterprise Docker image;
- compares the pull request with its target branch;
- fails when the OpenAPI contract is incompatible.

The important command is:

```shell
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v ${PWD}:/workspace \
  -v ${PWD}/bcc-enterprise-demo/license.txt:/specmatic/specmatic-license.txt:ro \
  -w /workspace \
  -e SPECMATIC_LICENSE_PATH=/specmatic/specmatic-license.txt \
  specmatic/enterprise:latest \
  backward-compatibility-check \
  --base-branch origin/main \
  --repo-dir /workspace \
  --target-path bcc-enterprise-demo/specs/baseline/openapi
```

This follows the backward-compatibility lab: run it from the repository root so `/workspace` contains both `.git` and `bcc-enterprise-demo`. Mounting only `bcc-enterprise-demo` hides the Git metadata, so Specmatic cannot resolve `origin/main`. The workflow also fetches and verifies the pull request's base ref before running BCC.

## 3. Commit the workflow

From the repository root:

```shell
git add .github/workflows/bcc.yml
git commit -m "Add OpenAPI backward compatibility CI check"
git push origin main
```

Confirm that the workflow appears under the repository's **Actions** tab.

## 4. Create the failing CI example

Create a branch:

```shell
git switch main
git pull
git switch -c demo-ci-offset
```

Apply the breaking change:

```shell
cd bcc-enterprise-demo
./scripts/customer_orders.sh --add-offset
git add specs/baseline/openapi/customer_orders.yaml
```

For this intentional demonstration change, create the commit with:

```shell
git commit --no-verify -m "Demo: make order offset mandatory"
```

Push the branch and open a pull request:

```shell
git push -u origin demo-ci-offset
```

Expected result:

```text
Customer Orders: INCOMPATIBLE
CI CHECK FAILED
```

The pull request is stopped because the proposed contract breaks existing consumers.

## 5. Create the passing CI example

Create a fresh branch from `main`:

```shell
git switch main
git pull
git switch -c demo-ci-skip
```

Apply the compatible change:

```shell
cd bcc-enterprise-demo
./scripts/customer_orders.sh --add-size
git add specs/baseline/openapi/customer_orders.yaml
git commit -m "Demo: add optional order page size"
git push -u origin demo-ci-size
```

Open a second pull request.

Expected result:

```text
OpenAPI: COMPATIBLE
CI CHECK PASSED
```

Show the two outcomes:

```text
mandatory offset → CI failed
optional size    → CI passed
```

## 6. Make the CI check block merging

In GitHub, open **Settings → Branches** and add a protection rule for `main`:

1. Require a pull request before merging.
2. Require status checks to pass before merging.
3. Select `BCC / OpenAPI baseline` as a required check.
4. Save the rule.

Without this branch-protection setting, GitHub Actions can report a failed check but GitHub will still allow the pull request to merge.

## 7. Presentation narration

> We ran the same BCC check locally and in the pull request. The only difference is the baseline: locally we compare with `main`; in CI we compare with the pull request's target branch. The one customer-orders contract lets us show several compatibility surfaces without switching demos.

## 8. Clean up the demonstration

After the presentation:

```shell
git switch main
git branch -D demo-ci-offset
git branch -D demo-ci-size
git push origin --delete demo-ci-offset
git push origin --delete demo-ci-size
```

Keep the workflow, the `SPECMATIC_LICENSE_ENV` environment, and its license secret in place. The local `license.txt` remains ignored.

## Acceptance criteria

- A pull request changing `offset` to mandatory fails.
- A pull request adding optional `size` passes.
- The check runs through Docker.
- The check runs with the demo Docker image.
- The workflow compares against the pull request's base branch.
- The failing demo commit uses `--no-verify` so CI, rather than the local hook, displays the failure.
- Branch protection marks `BCC / OpenAPI baseline` as required.
