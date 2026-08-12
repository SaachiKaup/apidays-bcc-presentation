# Enterprise Backward Compatibility Demo

You are a product shipping company. Your customer base has been steadily expanding, increasing the load on your systems. You want to redesign the platform to handle that load, reduce failures, and provide customers with granular order updates instead of only a single status.

The provider is considering several reasonable changes. The question is whether existing consumers will continue to work when the contract changes.

OpenAPI is the detailed demonstration. GraphQL, gRPC, and AsyncAPI are short pre-canned demonstrations showing that the same BCC capability applies to other specification types.

## Why start with backward compatibility?

> If changing a web API response can make more than one in three mobile applications fail, how do we know which consumers are safe before we release?

An earlier study of 43 mobile applications found failures in more than 30% of observed cases when a web API response changed. A 2024 study of 681 open-source Android applications found an average of two API field compatibility issues per application in each release snapshot, and that fixing one took about three and a half months on average. Method-level analysis could also miss many field-level compatibility issues.

These studies measure different things: consumer failures in the first case, and field-level issues and repair time in the second. Together, they show why compatibility needs to be checked before release.

Sources: [mobile API response study](https://link.springer.com/article/10.1007/s10664-019-09713-w) and [2024 Android API field study](https://doi.org/10.1016/j.infsof.2024.107530).

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

Alternative command:

```shell
./scripts/customer_orders.sh --add-size
```

#### Make `offset` mandatory

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

Alternative command:

```shell
./scripts/customer_orders.sh --add-offset
```

The lesson is that adding an optional parameter is safe, while making a new parameter mandatory breaks existing requests.

### 2. Move order creation from synchronous to asynchronous

The provider wants to acknowledge an order immediately and create it in the background. This reduces the time a customer waits for the creation request and helps the system absorb higher load.

The provider changes:

```text
201 Created → 202 Accepted
```

The `202` response points the client to a monitor resource through the `Link` header, following the convention used in the Specmatic labs:

```http
HTTP/1.1 202 Accepted
Link: </monitor/abc-123>;rel=related;title=monitor
```

Existing consumers may interpret `201` as “the order has been created.” Changing it to `202` changes that contract and is therefore breaking.

For the manual demo, comment out the active `201` response block and uncomment the `202` response marked **DEMO 3**. The asynchronous response does not pretend that the order is already complete; it returns an inline `Link` header that points to the monitor resource.

Alternative command:

```shell
./scripts/customer_orders.sh --async-create
```

The compatible file keeps only the safe evolution: `POST /orders` continues to return `201`. To deliberately introduce the asynchronous flow, use the versioned `specs/v1.0.1/openapi/customer_orders.yaml`, where the same endpoint returns `202` with an inline monitor link and `201` is removed.

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

Alternative command for the breaking change:

```shell
./scripts/customer_orders.sh --uuid-order-id
```

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

Alternative command:

```shell
./scripts/customer_orders.sh --replace-status
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

Alternative command:

```shell
./scripts/customer_orders.sh --add-updates
```

## Introducing a deliberate breaking change with a new API version

BCC protects existing consumers of the current API. It does not prevent the provider from making a breaking change when there is a real business reason; it makes the change visible so the provider can introduce it deliberately.

For example, use a new API version for the UUID migration or the asynchronous order-creation flow:

1. Keep the current contract unchanged as v1.
2. Copy the contract to a new versioned location, such as:

   ```text
   specs/v2/openapi/customer_orders.yaml
   ```

3. Update the new contract's `info.version`, for example from `1.0.0` to `2.0.0`.
4. Give the new API a distinct public route or server version, such as `/v2/orders` or `https://orders.example.test/v2`.
5. Make the breaking change only in v2: change `201` to `202`, change numeric IDs to UUIDs, or replace the status shape.
6. Keep v1 available while existing consumers migrate.
7. Run BCC separately against v2's intended baseline. The v2 baseline should be the contract that v2 consumers already depend on; do not compare a new v2 contract directly with an unrelated v1 contract and expect the breaking change to disappear.
8. Update consumers gradually, publish the migration guidance, and remove v1 only after the agreed deprecation period.

The version number in `info.version` documents the release, but it does not by itself make a breaking change safe. Compatibility comes from keeping the old version available or introducing a new contract boundary. Specmatic's BCC check should still run for each versioned contract and in CI.

For this demo, the prepared files illustrate the two sides:

```text
specs/baseline/openapi/customer_orders.yaml    current v1 contract
specs/breaking/openapi/customer_orders.yaml    proposed breaking release
specs/compatible/openapi/customer_orders.yaml  safe evolution of v1
specs/v1.0.1/openapi/customer_orders.yaml      versioned release with UUIDs and 202
```

The BCC command compares a changed contract with its Git baseline using `--base-branch`, and `--target-path` limits the check to the contract being demonstrated. See the [Specmatic backward compatibility documentation](https://docs.specmatic.io/contract_driven_development/backward_compatibility) for the workflow and command options.

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

The short demo command is:

```shell
docker run --rm -v ${PWD}:/usr/src/app \
  specmatic/specmatic:demo backward-compatibility-check \
  --base-branch main \
  --target-path bcc-enterprise-demo/specs/baseline/openapi
```

This checks the OpenAPI contracts in the target directory against `main`.

### Why an `OrderId` change can affect every operation

Yes, this is expected for the current UUID exercise. `OrderId` is a shared schema:

- `GET /orders/{orderId}` uses it as a path parameter and returns an `Order`;
- `POST /orders` returns an `Order`;
- `GET /orders` returns an `OrderList`, which contains `Order` objects;
- `GET /client_orders` also returns an `OrderList`.

Both `Order` and `OrderList` eventually refer to `OrderId`. Therefore, changing `OrderId` from an integer to a UUID changes the contract graph for all four operations. The report is not matching the word `orders`; it is showing the operations whose request or response contract depends on the changed shared schema. The `changed` markers show this propagated impact; the actual incompatibility is the shared ID type change.

For the short demo, this is useful: one shared schema change can affect many consumers, which is exactly why BCC needs to trace references across the specification.

For a more focused impact, change a schema used only by one operation, or add a separate schema for a new endpoint.

The fully explicit version of the same command is:

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
