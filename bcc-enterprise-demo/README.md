# Enterprise BCC Demo

This demo uses one OpenAPI contract, `specs/baseline/openapi/customer_orders.yaml`,
to show several enterprise changes and their backward-compatibility results.
The older GraphQL, gRPC, and AsyncAPI files remain as reference material; the
live demo uses only this customer-orders contract.

## Prerequisites

- Docker Desktop or Docker Engine with Compose v2;
- a valid Specmatic Enterprise license in `license.txt`.

Run commands from this directory:

```shell
cd bcc-enterprise-demo
```

## Run the menu

```shell
./scripts/customer_orders.sh
```

The menu offers:

```text
1) Add optional size — larger result sets need client-controlled page size (COMPATIBLE)
2) Make offset mandatory — every request must declare its page position (INCOMPATIBLE)
3) Change 404 to 422 — standardize order-not-found handling (INCOMPATIBLE)
4) Change numeric IDs to global string IDs — support international identifiers (INCOMPATIBLE)
5) Make status a richer object — expose code, reason, and update time (INCOMPATIBLE)
6) Apply all five changes
```

Direct options are also available:

```shell
./scripts/customer_orders.sh --add-size
./scripts/customer_orders.sh --add-offset
./scripts/customer_orders.sh --change-status
./scripts/customer_orders.sh --global-id
./scripts/customer_orders.sh --richer-status
```

The complete change, BCC, and cleanup flow is:

```shell
./scripts/run-bcc.sh customer-orders --add-offset
```

## Why each change is proposed

### Optional `size` — compatible

Order history is growing. Clients want to control the number of orders returned
per request, but existing clients should continue to work.

```yaml
- name: size
  in: query
  required: false
  schema:
    type: integer
    minimum: 1
    default: 20
```

Because it is optional, existing requests remain valid: `COMPATIBLE`.

### Mandatory `offset` — incompatible

The team wants every request to declare its position in a large result set.
Existing clients do not send `offset`, so their old requests become invalid.

```yaml
- name: offset
  in: query
  required: true
  schema:
    type: integer
    minimum: 0
```

Result: `INCOMPATIBLE`.

### `404` to `422` — incompatible

The platform is standardizing how clients interpret missing-order responses.
Status codes are part of the contract even when the response payload is not
changed.

```yaml
# Existing
'404':
  $ref: '#/components/responses/OrderNotFound'

# Proposed
'422':
  $ref: '#/components/responses/OrderNotFound'
```

Result: `INCOMPATIBLE` for clients that branch on `404`.

### Numeric ID to global string ID — incompatible

International expansion requires IDs such as `EU-XYZ123`, which cannot be
represented as integers.

```yaml
# Existing
id:
  type: integer
  example: 202600123

# Proposed
id:
  type: string
  example: EU-XYZ123
```

Result: `INCOMPATIBLE` for typed consumers expecting a number.

### Plain status to richer status object — incompatible

The company is integrating multiple carriers. `SHIPPED` alone is not enough
for tracking and support; they also need the reason and timestamp.

```json
// Existing
"status": "SHIPPED"

// Proposed
"status": {
  "code": "SHIPPED",
  "reason": "Carrier picked up the package",
  "updatedAt": "2026-08-10T12:00:00Z"
}
```

The object groups the values that describe one status event. Existing consumers
expecting a string now receive an object: `INCOMPATIBLE`.

## Compatible remediation examples

The prepared references show how to deliver the same business goals safely:

```text
specs/baseline/openapi/customer_orders.yaml    trusted contract
specs/breaking/openapi/customer_orders.yaml   proposed breaking release
specs/compatible/openapi/customer_orders.yaml safe redesign
```

The compatible version:

- keeps `offset` optional and gives it a default;
- keeps `404` and adds `422` separately;
- keeps numeric `id` and adds optional `internationalId`;
- keeps string `status` and adds optional `statusDetails`.

## Run BCC manually

From the repository root, run:

```shell
docker compose -f bcc-enterprise-demo/docker-compose.yml \
  run --rm --entrypoint specmatic bcc \
  backward-compatibility-check \
  --base-branch main \
  --repo-dir /workspace \
  --target-path bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml
```

Reports are written to `bcc-enterprise-demo/build/`.

## Cleanup

```shell
./scripts/cleanup.sh customer-orders
```

With no argument, cleanup restores all baseline specifications.

## Pre-commit and CI

Enable the hook from the repository root:

```shell
git config core.hooksPath bcc-enterprise-demo/.githooks
```

The guided pre-commit demonstration runs optional `size` first and mandatory
`offset` second:

```shell
./scripts/pre-commit-changes.sh
```

To deliberately send the breaking change to CI, bypass the local hook:

```shell
./scripts/customer_orders.sh --add-offset
git add specs/baseline/openapi/customer_orders.yaml
git commit --no-verify -m "Demo: make order offset mandatory"
git push -u origin demo-ci-offset
```

The pull-request workflow compares `customer_orders.yaml` with `origin/main`
and should fail with `INCOMPATIBLE`.
