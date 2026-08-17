# BCC Enterprise Demo Refactor Plan

## Story

The provider's order platform is growing internationally. The provider wants to handle larger result sets, acknowledge orders asynchronously, use globally unique IDs, and expose richer order history.

OpenAPI is the detailed story. GraphQL, gRPC, and AsyncAPI are short pre-canned demonstrations showing that BCC applies to other specification types.

## OpenAPI demonstrations

1. Add optional `size` to `GET /orders` — `COMPATIBLE`.
2. Make `offset` mandatory on `GET /orders` — `INCOMPATIBLE`.
3. Change `POST /orders` from `201` to `202` for asynchronous creation — `INCOMPATIBLE`.
4. Change numeric `orderId` to a UUID — `INCOMPATIBLE` and present as a deliberate versioned change.
5. Replace string `status` with an update-history array — `INCOMPATIBLE`.
6. Preserve string `status` and add optional `updates` — `COMPATIBLE`.

The OpenAPI baseline, breaking example, compatible example, scripts, README, and CI workflow must use these scenarios consistently.

## Pre-canned demonstrations

- GraphQL: make the existing optional `status` argument mandatory because the provider wants every query to filter by status.
- gRPC: change `order_id` from `int64` to `string` because global identifiers are required.
- AsyncAPI: change event `status` from a string to an object containing code, reason, and timestamp.

These demos only show the baseline, provider motivation, proposed change, BCC result, and cleanup. They do not include compatible-spec variants.

## Execution and CI

- Use Docker directly with one shared Specmatic BCC helper; Docker Compose is not required.
- Keep generated reports under `build/reports/specmatic/backward_compatibility/` and clear stale reports before each run.
- CI runs BCC against the pull request base branch and must return a non-zero status for incompatible changes, blocking merge.
- Cleanup restores the baseline files.

## Acceptance checks

- All scripts pass `sh -n`.
- All OpenAPI YAML files parse.
- Optional `size` passes BCC.
- Mandatory `offset`, `201 → 202`, UUID migration, and status replacement fail BCC.
- Preserving `status` and adding `updates` passes BCC.
- GraphQL, gRPC, and AsyncAPI pre-canned changes produce incompatible BCC results.
- CI blocks an incompatible OpenAPI pull request.
