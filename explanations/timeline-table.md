# Detailed Timeline

| Time | Section | What happens |
|---|---|---|
| **0:00–1:30** | Short opening story | Introduce the global order-fulfillment release and the risk of reasonable contract changes breaking existing consumers. |
| **1:30–7:30** | Main OpenAPI demonstration | Show optional `skip`/`limit` as compatible. Then make `limit` mandatory and change `404` to `422`, demonstrating request-parameter and status-code incompatibilities. Read the BCC findings. |
| **7:30–15:30** | Multi-specification BCC showcase | Spend roughly two minutes each on GraphQL, gRPC, and AsyncAPI. Show `customerName` → `buyerName`, `orderId` integer → string, and string `status` → structured event object, along with each scenario, BCC result, affected contract location, and a brief remediation option. Use the remaining time to compare the examples. |
| **15:30–16:30** | WIP | Mark the OpenAPI operation as `WIP`, make the breaking change, and show that the finding does not fail the check. Remove `WIP` and show the same change fail. |
| **16:30–18:30** | Compare the contract surfaces | Summarize parameters, status codes, GraphQL fields, protobuf types, and event payloads. Emphasize the shared baseline-to-proposed-contract workflow. |
| **18:30–19:30** | Pre-commit hook | Show the one-line hook that runs BCC before a commit. Keep this to one minute. |
| **19:30–20:30** | Choose the baseline | Explain `origin/main`, the last release tag, and other agreed trust points. |
| **20:30–23:30** | Pull requests and CI | Show the proposed contract being compared with the base branch, the incompatible PR failing, the report appearing as developer feedback, and the remediated PR passing. |
| **23:30–24:30** | Intentional breaking changes | Explain that deliberate breaks are explicitly reviewed, versioned or documented, and not silently ignored. |
| **24:30–25:00** | Closing | Different spec types, one compatibility gate, and actionable feedback before release. |
