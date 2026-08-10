# Proposed Talk Structure: One BCC Workflow Across Enterprise API Contracts

## Central Idea

A large enterprise rarely uses only OpenAPI. Different systems may use OpenAPI for REST APIs, GraphQL for customer applications, gRPC for internal services, and AsyncAPI for events.

These systems are different, but the business risk is the same:

> How do we know a contract change will not break consumers that already depend on it?

The talk presents Specmatic BCC as one compatibility workflow across all these spec types.

## Business Story

A global retailer is upgrading its order platform. Several changes are being proposed to support growth and improve customer and partner experiences:

- Order history is growing, so clients need pagination, and error handling is being standardized across the platform.
- Customer terminology needs to be standardized.
- International warehouses need globally unique order IDs.
- Shipping partners need richer delivery-status updates.

Each change solves a real problem. The risk is that existing consumers still depend on the current contracts.

| Contract | Business need | Proposed evolution |
|---|---|---|
| OpenAPI | Support larger order histories and standardize errors | Add optional `skip`/`limit`; make `limit` mandatory **and** change `404` to `422` |
| GraphQL | Standardize customer terminology | Rename `customerName` to `buyerName`; existing queries would fail |
| gRPC | Support international warehouse IDs | Change `orderId` from an integer to a string; existing generated clients may break |
| AsyncAPI | Provide richer status information to shipping partners | Change `status` from a string to a structured object; existing event consumers may fail |

## Demonstration Structure

1. **OpenAPI live demo** — Show optional `skip`/`limit` as compatible, then make `limit` mandatory and change `404` to `422` to demonstrate two different BCC findings.
2. **Multi-specification showcase** — Use prepared GraphQL, gRPC, and AsyncAPI examples. For each, show the business reason, proposed change, BCC result, and affected contract location.
3. **Common workflow** — Show how the same baseline-to-proposed-contract check can run locally, in pull requests, and in CI across all supported specification types.

## Confirmation Requested

Please confirm whether this structure and positioning work:

> One enterprise release, several legitimate changes, multiple spec types, and one compatibility gate across OpenAPI, GraphQL, gRPC, and AsyncAPI.
