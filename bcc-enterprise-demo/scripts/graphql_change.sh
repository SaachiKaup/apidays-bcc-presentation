#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/graphql/orders.graphqls"

if grep -q '^  buyerName: String!$' "$TARGET"; then
  echo "GraphQL: customerName has already been renamed to buyerName; leaving it unchanged."
  exit 0
fi

if ! grep -q '^  customerName: String!$' "$TARGET"; then
  echo "Could not find the baseline customerName field." >&2
  exit 1
fi

if [ "$(uname -s)" = "Darwin" ]; then
  sed -i '' 's/customerName: String!/buyerName: String!/' "$TARGET"
else
  sed -i 's/customerName: String!/buyerName: String!/' "$TARGET"
fi

echo "Changed GraphQL: customerName is now buyerName."
