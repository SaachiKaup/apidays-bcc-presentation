# Enterprise Backward Compatibility Demo

You are an e-commerce company. Your customer base has been steadily expanding, increasing the load on your services. You want to redesign the platform to handle that load, reduce failures, and provide customers with granular order updates instead of only a single status.

The provider is considering several reasonable changes. The question is whether existing consumers will continue to work when the contract changes.

OpenAPI is the detailed demonstration. GraphQL, gRPC, and AsyncAPI are short demonstrations showing that the same BCC capability applies to other specification types.

## Why start with backward compatibility?

> If changing a web API response can make more than one in three mobile applications fail, how do we know which consumers are safe before we release?

An earlier study of 43 mobile applications found failures in more than 30% of observed cases when a web API response changed. A 2024 study of 681 open-source Android applications found an average of two API field compatibility issues per application in each release snapshot, and that fixing one took about three and a half months on average. Method-level analysis could also miss many field-level compatibility issues.

These studies measure different things: consumer failures in the first case, and field-level issues and repair time in the second. Together, they show why compatibility needs to be checked before release.

Sources: [mobile API response study](https://link.springer.com/article/10.1007/s10664-019-09713-w) and [2024 Android API field study](https://doi.org/10.1016/j.infsof.2024.107530).

## Prerequisites

- Docker Desktop or Docker Engine;
- a valid Specmatic Enterprise license in `license.txt`.

The demo must use a valid Enterprise license. If the output says that the license is expired or that a trial license is being used, replace `license.txt` before presenting; do not present the trial-license output.

Run from the repository root, the directory containing `bcc-enterprise-demo`:

```shell
pwd
```

## The provider's proposed changes

Start from a clean, committed baseline. Create a separate demonstration branch before changing a specification:

```shell
git switch -c demo-bcc-changes
```

The baseline is already committed on `main`. The sequence is intentional: make one change, commit it, and then run BCC against the baseline. This lets the audience see the actual change and the compatibility result without first accumulating unrelated edits.

### 1. Paginate the order history

Customers have an increasing number of orders. The provider wants clients to retrieve the order history in manageable pages using `size` and `offset`.

The important question is not whether pagination is useful. It is whether the new parameters are required.

#### Add optional `size` — COMPATIBLE

An optional `size` lets new clients control the number of orders returned. Existing requests do not need to change.

In `bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml`, uncomment the `size` block marked **DEMO 1** under `GET /orders`.

```yaml
# main                         demo branch
# GET /orders                  GET /orders
# no size parameter             size: optional, default: 20

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
./bcc-enterprise-demo/scripts/customer_orders.sh --add-size
```

Commit the change, then run BCC:

```shell
git add bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml
git commit -m "Demo: add optional order page size"
./bcc-enterprise-demo/scripts/specmatic-bcc.sh bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml
```

Expected result: `COMPATIBLE`. The report should show the operation as checked and the compatible scenarios as passing. If a scenario is marked as changed, open it and show the exact request or response comparison; the important point is that the compatibility verdict passes.

#### Make `offset` mandatory

The provider may later decide that every request must explicitly state its position in the result set. Existing clients do not send `offset`, so their requests become invalid.

Replace the active pagination parameter area with the commented `offset` block marked **DEMO 2**.

```yaml
# main                         demo branch
# offset is absent             offset: required

- name: offset
  in: query
  required: true
  schema:
    type: integer
    minimum: 0
```

Alternative command:

```shell
./bcc-enterprise-demo/scripts/customer_orders.sh --add-offset
```

The lesson is that adding an optional parameter is safe, while making a new parameter mandatory breaks existing requests. Do not apply this breaking change to the committed v1 baseline during the main demo. Keep it as a proposed versioned change, or use a temporary demo branch when you need to show the failing report.

### 2. Move order creation from synchronous to asynchronous

The provider wants to acknowledge an order immediately and create it in the background. This reduces the time a customer waits for the creation request and helps the service absorb higher load.

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

For the manual demo, compare the current `201` response with the proposed `202` response side by side. The asynchronous response does not pretend that the order is already complete; it returns an inline `Link` header that points to the monitor resource.

```yaml
# v1 response                  proposed versioned response
# '201': Created                '202': Accepted
# order is created              order is queued
# no monitor link               Link: </monitor/{id}>;rel=related
```

Alternative command:

```shell
./bcc-enterprise-demo/scripts/customer_orders.sh --async-create
```

The compatible file keeps only the safe evolution: `POST /orders` continues to return `201`. To deliberately introduce the asynchronous flow, use the versioned `bcc-enterprise-demo/specs/v2.0.0/openapi/customer_orders.yaml`, where the same endpoint returns `202` with an inline monitor link and `201` is removed.

### 3. Move from numeric IDs to UUIDs — INCOMPATIBLE

As the customer base grows internationally, the provider wants an identifier system that is globally unique and easier to allocate across regions. Existing consumers currently expect numeric order IDs.

Replace the active `OrderId` schema in the new versioned file with the UUID version marked **DEMO 4**:

```yaml
type: string
format: uuid
example: 550e8400-e29b-41d4-a716-446655440000
```

Typed clients, databases, and integrations that expect an integer will no longer work. This is a deliberate breaking change to push through by introducing a new API version or a new identifier field and migrating consumers gradually.

The compatible design preserves the numeric ID and adds an optional UUID field such as `globalOrderId`.

Alternative command for the breaking change:

```shell
./bcc-enterprise-demo/scripts/customer_orders.sh --uuid-order-id
```

### 4. Provide granular order updates

Customers and support teams need more than `SHIPPED`. They want updates such as `LEFT_WAREHOUSE`, a timestamp, and an operational explanation such as “Left the Bengaluru warehouse.”

#### Replace `status` with update history — INCOMPATIBLE

Replacing the existing string status with an array changes the payload shape. Existing consumers that read `status` as a string will fail.

Replace the active `OrderStatus` schema in the proposed versioned file with the commented array marked **DEMO 5**:

```yaml
status:
  type: array
  items:
    $ref: '#/components/schemas/OrderUpdate'
```

Alternative command:

```shell
./bcc-enterprise-demo/scripts/customer_orders.sh --replace-status
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
./bcc-enterprise-demo/scripts/customer_orders.sh --add-updates
```

## Introducing a deliberate breaking change with a new API version

BCC protects existing consumers of the current API. It does not prevent the provider from making a breaking change when there is a real business reason; it makes the change visible so the provider can introduce it deliberately.

For example, use a new API version for the UUID migration or the asynchronous order-creation flow:

1. Keep the current contract unchanged as v1.
2. Copy the contract to a new versioned location, such as:

   ```text
   bcc-enterprise-demo/specs/v2.0.0/openapi/customer_orders.yaml
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
bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml    current v1 contract
bcc-enterprise-demo/specs/breaking/openapi/customer_orders.yaml    proposed breaking release
bcc-enterprise-demo/specs/compatible/openapi/customer_orders.yaml  safe evolution of v1
bcc-enterprise-demo/specs/v2.0.0/openapi/customer_orders.yaml      versioned release with UUIDs and 202
```

The versioned file is the place for deliberate breaking changes. The current v1 specification remains the consumer promise. A `specmatic.yaml` file in this demo points contract-based testing at the v2 specification, so the version boundary is explicit rather than inferred from a filename alone.

The BCC command compares a changed contract with its Git baseline using `--base-branch`, and `--target-path` limits the check to the contract being demonstrated. See the [Specmatic backward compatibility documentation](https://docs.specmatic.io/contract_driven_development/backward_compatibility) for the workflow and command options.

## Practice the OpenAPI changes manually

The baseline file contains the current v1 contract and commented examples for safe rehearsal. Versioned files contain deliberate breaking proposals. For each exercise:

1. Start from the committed baseline.
2. Uncomment only the block for the exercise.
3. If the comment says “replace,” comment out the current active definition first.
4. Run BCC.
5. Inspect the result and the generated report.
6. Restore the baseline before the next exercise, unless you are intentionally working in the versioned proposal file.

The helper can apply the equivalent changes automatically, but it is not required for the demo. Its breaking-change options edit the baseline for rehearsal, so use them only on a separate demonstration branch; the actual deliberate breaking release belongs in a versioned proposal file:

```shell
./bcc-enterprise-demo/scripts/customer_orders.sh --add-size
./bcc-enterprise-demo/scripts/customer_orders.sh --add-offset
./bcc-enterprise-demo/scripts/customer_orders.sh --async-create
./bcc-enterprise-demo/scripts/customer_orders.sh --uuid-order-id
./bcc-enterprise-demo/scripts/customer_orders.sh --replace-status
./bcc-enterprise-demo/scripts/customer_orders.sh --add-updates
```

## Run BCC with Docker

From the repository root, the lab-style command is:

The command used in the demo is:

```shell
docker run --rm -v ${PWD}:/usr/src/app \          
    specmatic/enterprise backward-compatibility-check \
    --base-branch main \
    --target-path bcc-enterprise-demo/specs/baseline/openapi
```

This checks the OpenAPI contracts in the target directory against `main`. Use the same check locally **and** in CI. In CI, the baseline is normally `origin/${{ github.event.pull_request.base.ref }}`; locally, use the local `main` or the last fetched `origin/main`, depending on the consumer baseline being protected.

The same command is available through the helper script:

```shell
./bcc-enterprise-demo/scripts/specmatic-bcc.sh \
  bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml
```

Reports are written to `build/reports/specmatic/backward_compatibility/`.

## Short demonstrations for other specification types

These are intentionally brief. Show the baseline, state the provider motivation, uncomment the commented change in the baseline file, and run the command.

### GraphQL

The customer portal wants to filter orders by status. The provider makes the existing `status` argument mandatory, assuming every client can now provide it. Older queries may omit it, so they no longer match the schema.

In `bcc-enterprise-demo/specs/baseline/graphql/orders.graphqls`, replace the active `orders` field with the commented version that uses `status: OrderStatus!`.

```shell
./bcc-enterprise-demo/scripts/demo.sh graphql
```

Expected result: `INCOMPATIBLE`.

### gRPC

The provider wants globally unique order IDs. In `bcc-enterprise-demo/specs/baseline/grpc/warehouse.proto`, replace `int64 order_id` with the commented string field.

```shell
./bcc-enterprise-demo/scripts/demo.sh grpc
```

Expected result: `INCOMPATIBLE`.

### AsyncAPI

The provider wants shipping consumers to receive a status code, reason, and timestamp. In `bcc-enterprise-demo/specs/baseline/asyncapi/shipping-events.yaml`, replace the string `status` with the commented object.

```shell
./bcc-enterprise-demo/scripts/demo.sh asyncapi
```

Expected result: `INCOMPATIBLE`.

No compatible variants are required for these three short demonstrations.

## CI merge protection

The GitHub Actions workflow runs BCC for OpenAPI pull requests using the same Enterprise Docker image and the same compatibility check shown above:

```shell
docker run --rm -v ${PWD}:/usr/src/app \          
    specmatic/enteprise backward-compatibility-check \
    --base-branch main \
    --target-path bcc-enterprise-demo/specs/baseline/openapi
```

The workflow fails when BCC returns a non-zero exit code. A breaking change such as mandatory `offset`, `201 → 202`, UUID migration, or replacing `status` therefore appears as a failed check.

To make that failed check prevent merging, configure GitHub branch protection:

1. Open **Settings → Branches → Branch protection rules**.
2. Add a rule for `main`.
3. Enable **Require a pull request before merging**.
4. Enable **Require status checks to pass before merging**.
5. Search for and select `BCC / OpenAPI baseline`.
6. Save the rule.

After this, a pull request with an incompatible baseline spec cannot be merged until the change is redesigned, versioned, or otherwise resolved.

The local check and the CI check are complementary: local BCC gives fast feedback while editing, and CI protects the shared branch against changes that were not checked locally or were introduced through another workflow.

## Cleanup

Restore all baseline specifications:

```shell
./bcc-enterprise-demo/scripts/cleanup.sh
```

Restore one short-demo baseline:

```shell
./bcc-enterprise-demo/scripts/cleanup.sh graphql
./bcc-enterprise-demo/scripts/cleanup.sh grpc
./bcc-enterprise-demo/scripts/cleanup.sh asyncapi
```
