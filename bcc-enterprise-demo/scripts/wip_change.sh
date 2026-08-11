#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/openapi/orders.yaml"

# Apply the breaking pagination change first.
sh "$SCRIPT_DIR/openapi_change.sh" --add-limit

if grep -A3 -q '^      summary: List orders for a customer$' "$TARGET" && \
   grep -A3 -q '^        - WIP$' "$TARGET"; then
  echo "OpenAPI WIP: the order-history operation is already marked WIP; leaving it unchanged."
  exit 0
fi

# Mark the affected operation as work in progress.
awk '
  /^      summary: List orders for a customer$/ {
    print
    print "      tags:"
    print "        - WIP"
    next
  }
  { print }
' "$TARGET" > "$TARGET.tmp"
mv "$TARGET.tmp" "$TARGET"

if ! grep -A2 -q '^      summary: List orders for a customer$' "$TARGET" || \
   ! grep -A2 -q '^      tags:$' "$TARGET"; then
  echo "Could not add the WIP tag to the order-history operation." >&2
  exit 1
fi

echo "Changed OpenAPI WIP scenario: limit is mandatory and the order-history operation is tagged WIP."
