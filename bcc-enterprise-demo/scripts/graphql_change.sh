#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/graphql/orders.graphqls"

if grep -q '^  deliveryDate: DateTime!$' "$TARGET"; then
  echo "GraphQL: deliveryDate is already non-null; leaving it unchanged."
  exit 0
fi

if ! grep -q '^  deliveryDate: DateTime$' "$TARGET"; then
  echo "Could not find the baseline nullable deliveryDate field." >&2
  exit 1
fi

if [ "$(uname -s)" = "Darwin" ]; then
  sed -i '' 's/deliveryDate: DateTime$/deliveryDate: DateTime!/' "$TARGET"
else
  sed -i 's/deliveryDate: DateTime$/deliveryDate: DateTime!/' "$TARGET"
fi

echo "Changed GraphQL: deliveryDate is now required (non-null)."
