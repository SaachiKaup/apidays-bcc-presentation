#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/graphql/orders.graphqls"

git -C "$ROOT" diff --quiet -- "$TARGET" || { echo "Target already changed: $TARGET" >&2; exit 1; }
git -C "$ROOT" diff --cached --quiet -- "$TARGET" || { echo "Target is staged: $TARGET" >&2; exit 1; }

if [ "$(uname -s)" = "Darwin" ]; then
  sed -i '' 's/customerName: String!/buyerName: String!/' "$TARGET"
else
  sed -i 's/customerName: String!/buyerName: String!/' "$TARGET"
fi

echo "Changed GraphQL: customerName is now buyerName."
