#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/graphql/orders.graphqls"

if grep -q '^  orders(status: OrderStatus!, skip: Int = 0, limit: Int = 20): \[Order!\]!$' "$TARGET"; then
  echo "GraphQL: the status argument is already mandatory; leaving it unchanged."
  exit 0
fi

if ! grep -q '^  orders(status: OrderStatus, skip: Int = 0, limit: Int = 20): \[Order!\]!$' "$TARGET"; then
  echo "Could not find the baseline optional status argument." >&2
  exit 1
fi

if [ "$(uname -s)" = "Darwin" ]; then
  sed -i '' 's/orders(status: OrderStatus, skip: Int = 0, limit: Int = 20): \[Order!\]!/orders(status: OrderStatus!, skip: Int = 0, limit: Int = 20): [Order!]!/' "$TARGET"
else
  sed -i 's/orders(status: OrderStatus, skip: Int = 0, limit: Int = 20): \[Order!\]!/orders(status: OrderStatus!, skip: Int = 0, limit: Int = 20): [Order!]!/' "$TARGET"
fi

echo "Changed GraphQL: the status argument is now mandatory."
