# Enterprise BCC Demo Plan

## Central Story

The company is preparing a global order-fulfillment release. It needs to handle more orders, support international identifiers, improve customer visibility, and publish richer shipment events.

None of the teams is making an unreasonable change. Each change addresses a valid business or engineering need. The risk is that existing consumers already depend on the current contracts.

The central question is:

> How can one enterprise detect breaking changes across different contract types before the release reaches consumers?

## Contract Changes in the Release

| Contract | Business motivation | Compatible change | Breaking change |
|---|---|---|---|
| OpenAPI | Order history is too large to return at once, and the API team is standardizing errors | Add optional `skip` and `limit` query parameters for pagination | Make `limit` mandatory, or change an existing error from `404` to `422` |
| GraphQL | The customer portal is standardizing terminology with the rest of the order platform | Add an optional `estimatedDelivery` field | Rename `customerName` to `buyerName`, breaking existing queries that select `customerName` |
| gRPC | The warehouse system needs globally unique order IDs | Add an optional `warehouseId` field | Change `orderId` from an integer to a string, or change the RPC error semantics |
| AsyncAPI | Shipping partners need richer status information | Add an optional `trackingUrl` field to the event | Change `status` from a string such as `"SHIPPED"` into an object containing `code`, `reason`, and `updatedAt` |

## How to Present the Story

### 1. Establish the enterprise release

Explain that four teams are evolving four different contracts as part of one global fulfillment release:

- REST/OpenAPI for external order-history clients;
- GraphQL for the customer portal;
- gRPC for internal warehouse services;
- AsyncAPI for shipment-status events consumed by partners.

Emphasize that the teams have valid motivations. The issue is not whether the features are useful; it is whether the proposed contract changes remain safe for existing consumers.

### 2. Demonstrate OpenAPI in detail

Use the Reports or order-history pagination example as the main live demonstration:

- adding an optional filter is compatible;
- making `limit` mandatory is incompatible;
- changing an array response into a pagination object is incompatible;
- retaining the old response shape or introducing a separate endpoint is a safe redesign.

This gives the audience a concrete understanding of backward compatibility before introducing the other specification types.

### 3. Show the prepared multi-spec demonstration

For GraphQL, gRPC, and AsyncAPI, use short prepared examples. Do not teach each technology in depth. For each contract, show the same four beats:

1. The trusted baseline.
2. The proposed business-driven change.
3. The BCC result.
4. The consumer expectation at risk.

The examples should vary by specification so the demonstration shows different compatibility surfaces rather than repeating the OpenAPI example:

- OpenAPI: request parameters, response shape, and status-code semantics;
- GraphQL: field selection and schema evolution—for example, renaming `customerName` to `buyerName`;
- gRPC: RPC methods and protobuf message types;
- AsyncAPI: channels, operations, and message payloads—for example, changing a string `status` into a structured status object.

The documentation describes BCC as checking the interface surface across protocol semantics, operations/endpoints/message channels, request/response and payload schemas, parameters, status codes, media types, and security schemes. The talk only needs to select a few representative areas, with status codes included as the less obvious example.

### 4. Explain the common workflow

The protocols differ, but the release workflow is consistent:

```text
Trusted contract
      ↓
Proposed contract
      ↓
Backward compatibility check
      ↓
Compatible or incompatible
      ↓
Safely evolve, reject, or explicitly approve
```

The message is not that the four specifications form one request path. The message is that one enterprise needs one compatibility gate across its contract estate.

### 5. Close with CI

Show a pull-request or CI check that compares each proposed contract with its agreed baseline and reports unapproved incompatibilities before release.

## Suggested Narration

> None of these teams is doing anything unreasonable. The REST team is managing scale. The frontend team is improving the customer experience. The warehouse team is preparing for global identifiers. The event team is giving partners more useful status information. The problem is that each change may violate a contract that existing consumers already depend on.

> The syntax changes across OpenAPI, GraphQL, gRPC, and AsyncAPI, but the engineering question remains the same: will the consumers that already depend on this contract continue to work?

## Core Message

> One enterprise release. Several legitimate changes. Many existing consumers. One compatibility gate.
