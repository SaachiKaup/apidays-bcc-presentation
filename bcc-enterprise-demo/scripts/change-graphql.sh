#!/bin/sh

set -eu

ROOT=/workspace
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/graphql/orders.graphqls"

git -C "$ROOT" diff --quiet -- "$TARGET" || { echo "Target already changed: $TARGET" >&2; exit 1; }
git -C "$ROOT" diff --cached --quiet -- "$TARGET" || { echo "Target is staged: $TARGET" >&2; exit 1; }

sed -i 's/customerName: String!/buyerName: String!/' "$TARGET"

echo "Changed GraphQL: customerName is now buyerName."
