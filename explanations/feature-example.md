# Feature Example

## Opening Demo

Start with the outcome rather than the background: “We are adding pagination and filtering to an existing Reports API. Will existing consumers continue to work?” Run the BCC check against the trusted baseline and the proposed contract, then inspect the findings.

Feature: Add pagination and filtering to an existing Reports API so it can support large datasets.

Current response:

GET /reports → 200 OK

```json
[
  { "id": 1, "name": "Sales" }
]
```

Proposed changes:

1. Add an optional status filter.

The team adds the filter as optional so existing callers can continue using the endpoint unchanged.

BCC result: Compatible. Existing consumers can ignore it.

2. Make limit mandatory.

The team makes limit mandatory to control query cost. Existing consumers do not send it.

BCC result: Incompatible. Existing requests no longer satisfy the contract.

3. Change the response type from an array to an object containing pagination metadata.

The team needs to return pagination details, so it wraps the existing array in a new object.

New response:

```json
{
  "reports": [
    { "id": 1, "name": "Sales" }
  ],
  "skip": 0,
  "limit": 20
}
```

BCC result: Incompatible. Existing consumers expect the response type to be an array, not an object.

The feature is valid. The problem is that the team modifies the existing contract to implement it. Specmatic identifies these incompatibilities before the pull request is merged.

## Quick Multi-Spec Showcase

Follow the Reports API demo with a short pre-canned comparison showing that enterprise compatibility is not limited to OpenAPI:

- OpenAPI: adding a required request field or changing a response shape breaks existing callers.
- AsyncAPI: removing an event field or changing its type breaks existing message consumers.
- GraphQL: removing a field or changing its type breaks existing queries and clients.
- gRPC: removing or reusing a protobuf field or changing an RPC contract can break generated clients.

For each example, show the baseline, the proposed contract, the BCC result, and the consumer expectation at risk. The message is simple: enterprises need one compatibility guardrail across the specifications they actually use.
