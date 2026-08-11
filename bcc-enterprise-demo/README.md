# Enterprise BCC Demo

This Docker-only demo shows Specmatic Backward Compatibility across four specification types used by an enterprise:

- OpenAPI for the order-history API;
- GraphQL for the customer portal;
- gRPC for warehouse services;
- AsyncAPI for shipment-status events.

The committed files under `specs/baseline/` are the trusted contracts. Each demonstration changes one baseline file in the working tree, runs the BCC check against the committed version, and offers to restore the file afterward.

## Prerequisites

- Docker Desktop or Docker Engine with Compose v2.
- A valid Specmatic Enterprise license in `license.txt`.
- A clean target specification before starting a demonstration.

Run all commands from this directory:

```shell
cd bcc-enterprise-demo
```

The license is mounted automatically from `./license.txt`. No host-installed Specmatic command or license environment variable is required.

## Run the demo

Run the interactive demonstration:

```shell
./scripts/run-bcc.sh
```

Or select a specification type directly:

```shell
./scripts/run-bcc.sh openapi
./scripts/run-bcc.sh graphql
./scripts/run-bcc.sh grpc
./scripts/run-bcc.sh asyncapi
```

The flow is:

1. Select or confirm the specification type.
2. Apply the selected business-driven change.
3. For OpenAPI, choose `skip`, `limit`, `404`→`422`, or all three.
4. Choose whether to run BCC.
5. See the Docker command used for the BCC check.
6. Choose whether to clean up the changed specification.

To apply all changes and answer the run and cleanup prompts automatically:

```shell
./scripts/run-bcc.sh openapi --yes
```

The BCC check always runs through the `specmatic/enterprise:latest` Docker image. The command shown during the demo is equivalent to:

```shell
docker compose -f ./docker-compose.yml run --rm \
  --entrypoint specmatic bcc backward-compatibility-check \
  --base-branch main \
  --repo-dir /workspace \
  --target-path bcc-enterprise-demo/specs/baseline/openapi/orders.yaml
```

The target path changes for GraphQL, gRPC, and AsyncAPI.

## Demonstrations and expected results

Each result is deliberately shown as only `COMPATIBLE` or `INCOMPATIBLE` for now. The detailed BCC explanation can be added to the presentation later.

### OpenAPI: order history and error handling

Order history is growing, so clients need pagination. Error handling is also being standardized across the platform.

#### Add optional `skip` — compatible

The first proposed change is pagination that does not force existing clients to change. The existing query parameters stay in place, and one optional parameter is added inline:

```yaml
parameters:
  - name: customerId
    in: query
    required: true
    schema:
      type: string
  - name: status
    in: query
    required: false
    schema:
      $ref: '#/components/schemas/OrderStatus'
  - name: skip
    in: query
    required: false
    schema:
      type: integer
      minimum: 0
      default: 0
```

Apply only this edit directly to the baseline spec:

```shell
./scripts/openapi_change.sh --add-skip
```

Run the same edit through the complete BCC flow:

```shell
./scripts/run-bcc.sh openapi --add-skip
```

```text
COMPATIBLE
```

Only the optional `skip` query parameter is added.

#### Add mandatory `limit` — incompatible

The next proposal is to require every client to control page size. Existing clients that omit `limit` can no longer make the same request:

```yaml
  - name: limit
    in: query
    required: true
    schema:
      type: integer
      minimum: 1
      default: 20
```

Apply only this edit directly to the baseline spec:

```shell
./scripts/openapi_change.sh --add-limit
```

Run the same edit through the complete BCC flow:

```shell
./scripts/run-bcc.sh openapi --add-limit
```

```text
INCOMPATIBLE
```

Only the mandatory `limit` query parameter is added.

#### Change `404` to `422` — incompatible

The platform is standardizing error handling. The proposed change replaces the missing-order response code:

```yaml
responses:
  '200':
    description: Order details
  '422':
    $ref: '#/components/responses/OrderNotFound'
```

The existing baseline uses `'404'` in this same location. Apply only the status-code edit:

```shell
./scripts/openapi_change.sh --change-status
```

Run the same edit through the complete BCC flow:

```shell
./scripts/run-bcc.sh openapi --change-status
```

```text
INCOMPATIBLE
```

Only the missing-order response status changes from `404` to `422`.

#### Apply all OpenAPI changes

The default OpenAPI change applies `skip`, mandatory `limit`, and `404`→`422` together:

```shell
./scripts/openapi_change.sh
```

This adds optional `skip`, adds mandatory `limit`, and changes `404` to `422`.

The complete BCC flow is:

```shell
./scripts/run-bcc.sh openapi --yes
```

The menu is still available when you want to choose interactively:

```shell
./scripts/openapi_change.sh --show-menu
```

```text
INCOMPATIBLE
```

The reference files are:

- `specs/compatible/openapi/orders.yaml` for optional pagination;
- `specs/breaking/openapi/orders.yaml` for mandatory pagination and `404`→`422`.

### GraphQL: terminology standardization

The customer portal is standardizing terminology. The change renames the `Order` field `customerName` to `buyerName`.

Run:

```shell
./scripts/run-bcc.sh graphql
```

```text
INCOMPATIBLE
```

Reference files:

- baseline: `specs/baseline/graphql/orders.graphqls`;
- compatible: `specs/compatible/graphql/orders.graphqls`;
- breaking: `specs/breaking/graphql/orders.graphqls`.

### gRPC: globally unique warehouse identifiers

International warehouses need IDs such as `EU-2026-00123`. The change modifies only `Order.order_id` in the response from `int64` to `string`.

Run:

```shell
./scripts/run-bcc.sh grpc
```

```text
INCOMPATIBLE
```

Reference files:

- baseline: `specs/baseline/grpc/warehouse.proto`;
- compatible: `specs/compatible/grpc/warehouse.proto`, which preserves `order_id` and adds `global_order_id`;
- breaking: `specs/breaking/grpc/warehouse.proto`.

### AsyncAPI: richer shipment status

Shipping partners need richer shipment information. The change modifies `status` from a string such as `SHIPPED` into an object containing `code`, `reason`, and `updatedAt`.

Run:

```shell
./scripts/run-bcc.sh asyncapi
```

```text
INCOMPATIBLE
```

Reference files:

- baseline: `specs/baseline/asyncapi/shipping-events.yaml`;
- compatible: `specs/compatible/asyncapi/shipping-events.yaml`, which keeps string `status` and adds optional `trackingUrl`;
- breaking: `specs/breaking/asyncapi/shipping-events.yaml`.

## Manual cleanup

If you decline cleanup, restore the selected file directly:

```shell
./scripts/cleanup.sh openapi
./scripts/cleanup.sh graphql
./scripts/cleanup.sh grpc
./scripts/cleanup.sh asyncapi
```

The cleanup script restores only the selected baseline specification from `HEAD`. Do not use `git reset --hard HEAD~1`; that would affect the entire repository and remove the baseline commit.

## Project structure

```text
bcc-enterprise-demo/
├── docker-compose.yml
├── license.txt                 # local, ignored by Git
├── scripts/
│   ├── run-bcc.sh
│   ├── openapi_change.sh
│   ├── graphql_change.sh
│   ├── grpc_change.sh
│   ├── asyncapi_change.sh
│   └── cleanup.sh
└── specs/
    ├── baseline/
    ├── compatible/
    └── breaking/
```
