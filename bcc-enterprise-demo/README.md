# Enterprise Backward Compatibility Demo

You are a product shipping company. Your customer base has been steadily expanding, increasing the load on your systems. You want to redesign the platform to handle that load, reduce failures, and provide customers with granular order updates instead of only a single status.

The provider is considering several reasonable changes. The question is whether existing consumers will continue to work when the contract changes.

OpenAPI is the detailed demonstration. GraphQL, gRPC, and AsyncAPI are short pre-canned demonstrations showing that the same BCC capability applies to other specification types.

## Prerequisites

- Docker Desktop or Docker Engine;
- a Specmatic Enterprise license in `license.txt`.

Run from the repository root unless a command says otherwise:

```shell
cd bcc-enterprise-demo
```

## The provider's proposed changes

### 1. Paginate the order history

Customers have an increasing number of orders. The provider wants clients to retrieve the order history in manageable pages using `size` and `offset`.

The important question is not whether pagination is useful. It is whether the new parameters are required.

#### Add optional `size` — COMPATIBLE

An optional `size` lets new clients control the number of orders returned. Existing requests do not need to change.

In `specs/baseline/openapi/customer_orders.yaml`, uncomment the `size` block marked **DEMO 1** under `GET /orders`.

```yaml
- name: size
  in: query
  required: false
  schema:
    type: integer
    minimum: 1
    default: 20
```

#### Make `offset` mandatory — INCOMPATIBLE

The provider may later decide that every request must explicitly state its position in the result set. Existing clients do not send `offset`, so their requests become invalid.

Replace the active pagination parameter area with the commented `offset` block marked **DEMO 2**.

```yaml
- name: offset
  in: query
  required: true
  schema:
    type: integer
    minimum: 0
```

The lesson is that adding an optional parameter is safe, while making a new parameter mandatory breaks existing requests.

### 2. Move order creation from synchronous to asynchronous

The provider wants to acknowledge an order immediately and create it in the background. This reduces the time a customer waits for the creation request and helps the system absorb higher load.

The provider changes:

```text
201 Created → 202 Accepted
```

The response can also include a monitor link so the client can check progress:

```json
{
  "monitorUrl": "/orders/requests/abc-123"
}
```

Existing consumers may interpret `201` as “the order has been created.” Changing it to `202` changes that contract and is therefore breaking.

For the manual demo, remove the active `201` response block and uncomment the `202` block marked **DEMO 3**.

Safe resolution options include preserving the existing `201` endpoint, introducing a new asynchronous endpoint, or versioning the API. A new optional monitor link can be added without changing existing consumers.

### 3. Move from numeric IDs to UUIDs — INCOMPATIBLE

As the customer base grows internationally, the provider wants an identifier system that is globally unique and easier to allocate across regions. Existing consumers currently expect numeric order IDs.

Replace the active `OrderId` schema with the commented UUID version marked **DEMO 4**:

```yaml
type: string
format: uuid
example: 550e8400-e29b-41d4-a716-446655440000
```

Typed clients, databases, and integrations that expect an integer will no longer work. This is a deliberate breaking change to push through by introducing a new API version or a new identifier field and migrating consumers gradually.

The compatible design preserves the numeric ID and adds an optional UUID field such as `globalOrderId`.

### 4. Provide granular order updates

Customers and support teams need more than `SHIPPED`. They want updates such as `LEFT_WAREHOUSE`, a timestamp, and an operational explanation such as “Left the Bengaluru warehouse.”

#### Replace `status` with update history — INCOMPATIBLE

Replacing the existing string status with an array changes the payload shape. Existing consumers that read `status` as a string will fail.

Replace the active `OrderStatus` schema with the commented array marked **DEMO 5**:

```yaml
status:
  type: array
  items:
    $ref: '#/components/schemas/OrderUpdate'
```

#### Preserve `status` and add `updates` — COMPATIBLE

The safe design keeps the existing status and adds a new optional field for the richer information. Uncomment both the `updates` field and the `OrderUpdate` schema marked **DEMO 6**.

```yaml
status:
  type: string

updates:
  type: array
  items:
    $ref: '#/components/schemas/OrderUpdate'
```

Existing consumers continue reading `status`; newer consumers can use `updates`.

## Practice the OpenAPI changes manually

The baseline file contains commented examples. For each exercise:

1. Start from the committed baseline.
2. Uncomment only the block for the exercise.
3. If the comment says “replace,” comment out the current active definition first.
4. Run BCC.
5. Inspect the result and the generated report.
6. Restore the baseline before the next exercise.

The helper can apply the equivalent changes automatically, but it is not required for the demo:

```shell
./scripts/customer_orders.sh --add-size
./scripts/customer_orders.sh --add-offset
./scripts/customer_orders.sh --async-create
./scripts/customer_orders.sh --uuid-order-id
./scripts/customer_orders.sh --replace-status
./scripts/customer_orders.sh --add-updates
```

## Run BCC with Docker

From the repository root:

```shell
docker run --rm \
  -v "$PWD:/workspace" \
  -v "$PWD/bcc-enterprise-demo/license.txt:/specmatic/specmatic-license.txt:ro" \
  -w /workspace \
  -e SPECMATIC_LICENSE_PATH=/specmatic/specmatic-license.txt \
  specmatic/enterprise:latest \
  backward-compatibility-check \
  --base-branch main \
  --repo-dir /workspace \
  --target-path bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml
```

The same command is available through:

```shell
./bcc-enterprise-demo/scripts/specmatic-bcc.sh \
  bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml
```

Reports are written to `build/reports/specmatic/backward_compatibility/`.

## Pre-canned demos for other specification types

These are intentionally brief. Show the baseline, state the provider motivation, uncomment the commented change in the baseline file, and run the command.

### GraphQL

The provider wants every order to display a delivery date. Older orders may not have one, so changing `deliveryDate` from nullable to non-null is breaking.

In `specs/baseline/graphql/orders.graphqls`, replace the active field with the commented `DateTime!` field.

```shell
./scripts/run-pre-canned.sh graphql
```

Expected result: `INCOMPATIBLE`.

### gRPC

The provider wants globally unique order IDs. In `specs/baseline/grpc/warehouse.proto`, replace `int64 order_id` with the commented string field.

```shell
./scripts/run-pre-canned.sh grpc
```

Expected result: `INCOMPATIBLE`.

### AsyncAPI

The provider wants shipping consumers to receive a status code, reason, and timestamp. In `specs/baseline/asyncapi/shipping-events.yaml`, replace the string `status` with the commented object.

```shell
./scripts/run-pre-canned.sh asyncapi
```

Expected result: `INCOMPATIBLE`.

No compatible variants are required for these three short demonstrations.

## CI merge protection

The GitHub Actions workflow runs BCC for OpenAPI pull requests. A breaking change such as mandatory `offset`, `201 → 202`, UUID migration, or replacing `status` must produce `INCOMPATIBLE` and a non-zero workflow exit, blocking the merge until the provider redesigns or versions the change.

## Cleanup

Restore all baseline specifications:

```shell
./bcc-enterprise-demo/scripts/cleanup.sh
```

Restore one pre-canned baseline:

```shell
./bcc-enterprise-demo/scripts/cleanup.sh graphql
./bcc-enterprise-demo/scripts/cleanup.sh grpc
./bcc-enterprise-demo/scripts/cleanup.sh asyncapi
```
