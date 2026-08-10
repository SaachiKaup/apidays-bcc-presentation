An API can be “working” and still be broken for its consumers.

In one project, an order-processing API evolved in a seemingly harmless release. A response field that had always been present for older clients was removed, an enum gained a new value, and one error case started returning a different status code. The producer’s tests passed. The new client worked. Existing consumers, however, either failed to deserialize the response or treated valid orders as failures. A relatively new product lost trust at exactly the point when users were still learning to depend on it.

This talk follows that incident and asks a practical question: how can a team know that a proposed API change is safe for consumers it cannot see? We will begin with a fast, concrete demo: a Reports API gains pagination and filtering, and a backward compatibility check immediately exposes the changes that break existing consumers. We will then show that the same guardrail applies beyond OpenAPI. Large enterprises commonly use AsyncAPI, GraphQL, gRPC, and other contract formats alongside REST, so the goal is one compatibility workflow across the API landscape—not a different tool for every specification type.

The session covers less obvious breaking changes—response-shape changes, enum expansion, status-code changes, and changes to error contracts—and shows how to distinguish a genuine incompatibility from a safe evolution. It includes a pre-canned comparison across OpenAPI, AsyncAPI, GraphQL, and gRPC contracts, followed by a PR/CI workflow that makes every compatibility exception explicit and intentional.

 
0 COMMENTS  visibility  ADD TO WATCHLIST
 Share on Facebook  Tweet  Share on LinkedIn  Share on Email
 
### Outline/Structure of the Talk

#### 1. Start with the demo: a feature that breaks an API — 0:00–6:00 (6 min)

1. Introduce the Reports API and the feature: pagination and filtering for large datasets.
2. Run the BCC check against the baseline and proposed contract.
3. Show three findings live: an optional filter is compatible, a newly mandatory `limit` is incompatible, and changing an array response into a paginated object is incompatible.
4. Keep the feature goal, redesign the API safely, and rerun the check.
5. Establish the cost: a contract break is worse than an ordinary bug because it violates behavior consumers were already entitled to expect.

#### 2. Why one enterprise needs compatibility across specs — 6:00–9:00 (3 min)

1. Define compatibility from the consumer’s point of view, not the producer’s.
2. Explain that enterprise systems use OpenAPI, AsyncAPI, GraphQL, gRPC, and other specification types together.
3. Show a quick pre-canned BCC demo for each spec type: a representative contract change, the compatibility result, and the consumer expectation protected.
4. Position Specmatic BCC as one workflow for finding breaking changes across these contracts.

#### 3. What counts as backward compatible? — 9:00–13:00 (4 min)

1. Contrast safe evolution with breaking evolution across request, response, event, query, and service contracts.
2. Explain why producer tests are insufficient: they validate what the new service does, not whether old consumers can still use it.
3. Explain why a tool is useful: the risk is distributed across operations, messages, schemas, fields, references, and error cases.

#### 4. From finding to engineering decision — 13:00–18:00 (5 min)

1. Turn each finding into one of three decisions: reject the PR, evolve the API safely, or approve an intentional exception.
2. Demonstrate how to document and time-limit an exception when a breaking change is unavoidable.
3. Clarify the baseline choice: last release tag for external consumers, or another explicitly agreed trust point for internal APIs.

#### 5. Put the guardrail in CI — 18:00–23:00 (5 min)

1. Show the PR check: checkout the baseline specification, compare it with the proposed specification, and fail on unapproved incompatibilities.
2. Show the developer feedback available in the pull request, before deployment or consumer discovery.
3. Mention how deliberate breaking changes are reviewed and overridden rather than silently ignored.

#### 6. Closing — 23:00–25:00 (2 min)

Backward compatibility is not about fixing ordinary bugs. It is about honoring expectations that APIs and events have already created. Whether the contract is OpenAPI, AsyncAPI, GraphQL, or gRPC, one compatibility workflow can expose the risk; teams can then reject, evolve, or override it deliberately.

Learning Outcome
You will be able to identify consumer-visible breaking changes that ordinary producer-side tests and code review can miss.
You will know how to choose a compatibility baseline, interpret a compatibility report, and decide whether to reject, evolve, or intentionally override a change.
You will be able to add a PR-time compatibility guardrail that fails on unapproved incompatibilities and gives developers actionable feedback before release.
Target Audience
Backend/API engineers, QA/SDET, tech leads, architects, and API product owners.

Prerequisites for Attendees
Attendees should be comfortable with OpenAPI/Swagger (or equivalent API contract format) and have basic familiarity with CI pipelines (GitHub Actions, GitLab CI, Jenkins, or similar).
