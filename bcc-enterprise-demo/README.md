# Enterprise BCC Demo

This is a Docker-only demonstration of Specmatic Backward Compatibility across four spec types used in a large enterprise:

- OpenAPI for the external order-history API;
- GraphQL for the customer portal;
- gRPC for warehouse services;
- AsyncAPI for shipment-status events.

The story is one global retailer upgrading its order platform. Each proposed change solves a real business problem, but existing consumers still depend on the current specs.

## Objective

Show one repeatable BCC workflow across multiple spec types:

```text
Trusted baseline
      ↓
Proposed specification
      ↓
Backward compatibility check
      ↓
Compatible or incompatible result
      ↓
Safe evolution or explicit review
```

## Prerequisites

- Docker Desktop or Docker Engine with Compose v2.
- A Specmatic Enterprise license file.
- No host Python, Node, Java, or package installation is required.

Set the license path before running the demo:

```shell
export SPECMATIC_LICENSE_FILE=/path/to/specmatic-license.txt
```

For the local labs checkout, this may be:

```shell
export SPECMATIC_LICENSE_FILE=/Users/saachikaup/Work/labs/license.txt
```

## Project structure

```text
bcc-enterprise-demo/
├── docker-compose.yml
├── scripts/run-bcc.sh
├── specs/
│   ├── baseline/
│   ├── compatible/
│   └── breaking/
└── build/
```

The baseline directory represents the trusted release. The compatible and breaking directories contain proposed releases. The runner derives the remediated scenario from the compatible files and derives the WIP scenario by applying the breaking OpenAPI change with a `WIP` tag. It creates a temporary Git repository inside the container, commits the baseline as `main`, overlays the selected scenario, and runs the current `backward-compatibility-check` command.

## Scenario 1: Show compatible evolution

Run:

```shell
docker compose run --rm bcc compatible
```

Expected result:

```text
(COMPATIBLE) The spec is backward compatible with the corresponding spec from main
```

This scenario demonstrates safe changes:

- OpenAPI adds optional `skip` and `limit` pagination parameters.
- GraphQL adds optional `estimatedDelivery`.
- gRPC adds `global_order_id` without changing `order_id`.
- AsyncAPI adds optional `trackingUrl`.

Reports are written under:

```text
build/reports/compatible/
```

## Scenario 2: Show the breaking release

Run:

```shell
docker compose run --rm bcc breaking
```

The wrapper exits successfully after demonstrating the expected failure, so the rehearsal can continue. The Specmatic command inside the container returns the incompatibility result.

The scenario contains these legitimate changes:

### OpenAPI: pagination and error standardization

Order history is growing. The proposed specification:

- makes `limit` mandatory;
- changes the missing-order response from `404` to `422`.

Expected BCC findings include a request-parameter incompatibility and a status-code incompatibility.

### GraphQL: terminology standardization

The customer portal is standardizing terminology. The proposed schema renames:

```graphql
customerName: String!
```

to:

```graphql
buyerName: String!
```

Existing queries selecting `customerName` no longer match the proposed schema.

### gRPC: globally unique warehouse identifiers

International warehouses need IDs such as `EU-2026-00123`. The proposed `.proto` changes `order_id` from `int64` to `string`. Existing generated clients expect the original message field type.

### AsyncAPI: richer shipment status

Shipping partners need more information than a status string. The proposed event changes:

```json
"status": "SHIPPED"
```

to a structured object containing `code`, `reason`, and `updatedAt`. Existing event consumers expect the original string payload shape.

Reports are written under:

```text
build/reports/breaking/
```

Open the generated HTML report and show the affected operation, channel, contract location, rule or mismatch, and plain-language difference.

## Scenario 3: Show the remediated release

Run:

```shell
docker compose run --rm bcc remediated
```

Expected result:

```text
(COMPATIBLE) The spec is backward compatible with the corresponding spec from main
```

The remediated scenario keeps the business direction while preserving existing consumers:

- OpenAPI keeps `limit` optional and preserves `404`.
- GraphQL keeps `customerName`, adds `buyerName`, and can deprecate the old field gradually.
- gRPC keeps numeric `order_id` and adds `global_order_id`.
- AsyncAPI keeps string `status` and adds optional `statusDetails`.

## Scenario 4: Show WIP behavior

Run:

```shell
docker compose run --rm bcc wip
```

This scenario applies the OpenAPI breaking change while marking the affected operation with the `WIP` tag. The check still reports feedback, but the WIP change does not fail the command.

Expected result:

```text
Expected result: WIP feedback was reported without failing the check
```

Use this to explain that WIP is for contracts still being designed. It should not be used to hide a breaking change in a finalized production spec.

## Scenario 5: Show the CI gate

Run:

```shell
docker compose run --rm bcc ci
```

This runs the breaking scenario as a pull-request gate. It demonstrates that an unapproved breaking change causes the CI check to fail.

In a real pipeline, the baseline would normally be `origin/main` or the last released spec, depending on which consumers the team needs to protect.

## What to show in the presentation

1. Run `compatible` briefly to establish that safe evolution passes.
2. Run `breaking` and focus on the OpenAPI report.
3. Use the prepared findings for GraphQL, gRPC, and AsyncAPI to show the different spec surfaces.
4. Run `remediated` to show the same release made safe.
5. Run `wip` in one minute to show design-in-progress behavior.
6. Finish with `ci` and the baseline/PR gate story.

## Cleanup

The demo containers are one-shot containers. If any container is still running:

```shell
docker compose down --remove-orphans
```

Generated reports can be removed from `build/` after the rehearsal.

## Troubleshooting

### License path is not set

Set `SPECMATIC_LICENSE_FILE` to an existing license file and rerun the command.

### Docker cannot mount the license

Use an absolute host path for `SPECMATIC_LICENSE_FILE`.

### An expected compatible scenario fails

Check that the baseline and scenario files have not been edited manually. The runner creates a fresh temporary Git repository for every run.

### Reports are not visible

Check the scenario-specific directory under `build/reports/`. The report is copied out of the temporary container repository after the command finishes.

## References

- [Specmatic Backward Compatibility](https://docs.specmatic.io/contract_driven_development/backward_compatibility)
- [Specmatic Backward Compatibility Rules](https://docs.specmatic.io/contract_driven_development/backward_compatibility_rules)
- [Specmatic backward-compatibility-testing lab](https://github.com/specmatic/labs/tree/main/backward-compatibility-testing)
