# Timeline

## 0:00–1:30 — Short opening story

Introduce the global order-fulfillment release and the risk of reasonable contract changes breaking existing consumers.

## 1:30–7:30 — Main OpenAPI demonstration

Show optional `skip` and `limit` pagination as a compatible change. Then make `limit` mandatory and change `404` to `422`, demonstrating request-parameter and status-code incompatibilities. Read the BCC findings.

## 7:30–15:30 — Multi-specification BCC showcase

Use prepared examples for GraphQL, gRPC, and AsyncAPI: make the optional GraphQL `status` argument mandatory, change `orderId` from an integer to a string, and change a string `status` into a structured event object. For each, show the business motivation, proposed change, BCC result, affected contract location, and a brief remediation option.

## 15:30–16:30 — WIP workflow

Show a breaking OpenAPI change marked `WIP`. BCC reports the issue without failing. Remove `WIP` and show the same change fail.

## 16:30–18:30 — Compare the contract surfaces

Summarize how BCC applies to parameters, status codes, GraphQL fields, protobuf types, and event payloads while following the same baseline-to-proposed-contract workflow.

## 18:30–19:30 — Pre-commit hook

Briefly show BCC running before a commit.

## 19:30–20:30 — Choose the baseline

Explain when to compare against `origin/main`, the last release tag, or another explicitly agreed trust point.

## 20:30–23:30 — Pull requests and CI

Show the incompatible pull request failing, the BCC report appearing as developer feedback, and the remediated pull request passing.

## 23:30–24:30 — Intentional breaking changes

Explain how deliberate breaks are reviewed, versioned or documented, and never silently ignored.

## 24:30–25:00 — Closing

Different spec types, one compatibility gate, and actionable feedback before release.
