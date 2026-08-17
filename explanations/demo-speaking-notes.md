# BCC Demo Speaking Notes

These notes are for presenting the demo. They are intentionally separate from the README, which should remain a practical guide for running it.

## Framing

- Describe the company as an e-commerce company.
- Use “service” consistently when describing the systems involved.
- Present OpenAPI as the detailed demonstration.
- Present GraphQL, gRPC, and AsyncAPI as short pre-canned demonstrations showing that BCC also works across different specification types.

## What to show in the BCC result

When a check reports an incompatibility, show the failed scenario rather than only the summary:

1. the operation or message being checked;
2. the changed contract location;
3. the old and proposed values side by side; and
4. why an existing consumer may no longer work.

For the compatible `size` change, show the same comparison and the passing verdict. This makes the distinction between a changed contract area and an incompatible change clear.

## Local and CI checks

The local and CI checks are complementary:

- local BCC gives fast feedback while editing;
- CI checks the pull request against its target branch and protects the shared branch.

The same Enterprise Docker image and BCC command should be used in both places.

## Shared schema example

The UUID exercise can affect several operations because `OrderId` is a shared schema. The report may therefore show the operations whose request or response contract depends on that schema.

The report is following the specification's references; it is not matching the word `orders`. The `changed` markers show propagated impact, while the final BCC verdict says whether the existing consumer contract remains compatible.

## License reminder

Use a valid Specmatic Enterprise license for the demonstration. Do not present output that says a trial license is being used or that the license is expired.
