# Enterprise BCC Demo

This Docker-only demo shows Specmatic Backward Compatibility across OpenAPI, GraphQL, gRPC, and AsyncAPI.

The baseline specs are committed in this repository. Each demonstration command applies one business-driven change to the working tree, shows the actual Specmatic command, and asks whether you want to clean up afterward.

## Prerequisites

- Docker Desktop or Docker Engine with Compose v2.
- A Specmatic Enterprise license file.
- The baseline demo files committed in the current Git branch.

The Compose file mounts `license.txt` from this directory into the container.

## Run a demonstration

Run one spec type:

```shell
docker compose run --rm -it bcc openapi
docker compose run --rm -it bcc graphql
docker compose run --rm -it bcc grpc
docker compose run --rm -it bcc asyncapi
```

If you do not supply a spec type, you can choose one from a numbered menu:

```shell
docker compose run --rm -it bcc
```

When you run a demonstration, it:

1. Applies the selected breaking change.
2. Asks whether to run BCC.
3. Prints the exact Specmatic command and runs it.
4. Asks whether to clean up.

Use `--yes` to answer both questions yes:

```shell
docker compose run --rm -it bcc openapi --yes
```

## Expected demonstrations

Each demonstration starts with the committed file under `specs/baseline/`, applies the proposed change to that same file, and runs BCC against the committed version. The output should be explained as a compatibility result, not just as a schema diff.

### OpenAPI: order history and error handling

#### 1. Add optional pagination — compatible

Order history is growing, so clients need pagination. Adding optional `skip` and `limit` query parameters does not invalidate existing requests because old clients can continue sending the request without them.

Expected result:

```text
COMPATIBLE
```

The committed `specs/compatible/openapi/orders.yaml` contains this safe reference version.

#### 2. Make `limit` mandatory — incompatible

The team now requires every client to control page size. Making `limit` required changes an existing request contract: clients that previously omitted it can no longer make the same request successfully.

Run the OpenAPI demonstration:

```shell
docker compose run --rm -it bcc openapi
```

Expected result:

```text
INCOMPATIBLE
```

#### 3. Change `404` to `422` — incompatible

Error handling is being standardized across the platform. Changing the missing-order response from `404 Not Found` to `422 Unprocessable Entity` changes the status-code contract that existing clients use to handle missing orders.

The OpenAPI script applies this change together with the mandatory `limit` change. The same run should also report:

```text
INCOMPATIBLE
```

The committed `specs/breaking/openapi/orders.yaml` contains the combined reference version.

### GraphQL: terminology standardization

The customer portal is standardizing terminology. The proposed change renames `customerName` to `buyerName`.

Run:

```shell
docker compose run --rm -it bcc graphql
```

Expected result:

```text
INCOMPATIBLE
```

The committed `specs/breaking/graphql/orders.graphqls` contains the proposed version. The compatible reference keeps `customerName` and adds only a new optional field.

### gRPC: globally unique warehouse identifiers

International warehouses need globally unique IDs such as `EU-2026-00123`. The proposed change changes the protobuf field `order_id` from `int64` to `string`.

Run:

```shell
docker compose run --rm -it bcc grpc
```

Expected result:

```text
INCOMPATIBLE
```

The committed `specs/breaking/grpc/warehouse.proto` contains the proposed version. The compatible reference preserves `order_id` and adds `global_order_id`.

### AsyncAPI: richer shipment status

Shipping partners need richer shipment information. The proposed event changes `status` from a string such as `SHIPPED` into an object containing `code`, `reason`, and `updatedAt`.

Run:

```shell
docker compose run --rm -it bcc asyncapi
```

Expected result:

```text
INCOMPATIBLE
```

The committed `specs/breaking/asyncapi/shipping-events.yaml` contains the proposed version. The compatible reference keeps `status` as a string and adds optional `trackingUrl`.

## The four changes

The four change scripts operate on the baseline files directly. The reference fixtures are retained under `specs/compatible/` and `specs/breaking/` for comparison while preparing the presentation.

## The visible BCC command

For OpenAPI, you will see and execute a command like:

```shell
specmatic backward-compatibility-check \
  --base-branch main \
  --repo-dir /workspace \
  --target-path bcc-enterprise-demo/specs/baseline/openapi/orders.yaml
```

The target path changes for GraphQL, gRPC, and AsyncAPI. The baseline is the committed version on `main`; the proposed version is the uncommitted working-tree change.

## Manual cleanup

If cleanup is declined, restore only the selected spec:

```shell
docker compose run --rm --entrypoint sh bcc \
  /workspace/bcc-enterprise-demo/scripts/cleanup.sh openapi
```

Equivalent direct Git command:

```shell
git restore --source=HEAD --worktree --staged -- \
  bcc-enterprise-demo/specs/baseline/openapi/orders.yaml
```

## Files

```text
bcc-enterprise-demo/
├── docker-compose.yml
├── scripts/
│   ├── run-bcc.sh
│   ├── change-openapi.sh
│   ├── change-graphql.sh
│   ├── change-grpc.sh
│   ├── change-asyncapi.sh
│   └── cleanup.sh
└── specs/
    ├── baseline/
    ├── compatible/
    └── breaking/
```

The `compatible` and `breaking` directories remain as reference fixtures. The interactive scripts operate on the committed `baseline` files so the audience can see a real working-tree change before BCC runs.

## Cleanup containers

The BCC container is one-shot. If needed:

```shell
docker compose down --remove-orphans
```
