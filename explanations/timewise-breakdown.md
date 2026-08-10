# Time-wise Breakdown

## 0:00–1:00 — Set the challenge

Open with the question: “We are changing an existing API—how do we know consumers we cannot see will still work?” Introduce the idea that enterprises use several API specification types.

## 1:00–6:30 — Actual Reports API demo

Introduce the Reports API and the pagination/filtering feature. Run BCC against the baseline and proposed OpenAPI contracts. Show that the optional status filter is compatible, the mandatory limit is incompatible, and the array-to-object response change is incompatible. Apply the safe redesign and rerun the check.

## 6:30–9:30 — One enterprise, many specification types

Explain that a large enterprise may use OpenAPI, AsyncAPI, GraphQL, and gRPC across different teams and products. Position the need for one BCC workflow across all of them.

## 9:30–13:00 — Quick pre-canned multi-spec demo

Show one representative breaking change and BCC result for each specification type:

- OpenAPI: required request field or response-shape change;
- AsyncAPI: removed event field or changed message type;
- GraphQL: removed field or changed field type;
- gRPC: incompatible protobuf/RPC change.

## 13:00–15:30 — What backward compatibility means

Define it simply: existing consumers should continue working without changing their requests, queries, messages, or response handling. A provider change becomes breaking when it violates those existing expectations.

## 15:30–18:00 — Redesign the feature safely

Keep the existing `GET /reports` contract unchanged. Introduce the new paginated response through a separate endpoint or version. Run the check again and show that the contract is now compatible.

## 18:00–20:00 — Local development and pre-commit hooks

Show how developers can run the check while changing the specification and add it as a pre-commit hook so breaking changes are detected before commit.

## 20:00–23:30 — Pull requests and CI

Show the check running against the base branch in CI. Demonstrate the original change failing the pull-request check and the corrected change passing.

Explain how the baseline can be `origin/main` or the last released specification, depending on which consumers need to be protected.

## 23:30–25:00 — Closing

Return to the main message: API evolution is safe only when it preserves the expectations already held by consumers.
