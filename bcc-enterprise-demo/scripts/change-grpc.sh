#!/bin/sh

set -eu

ROOT=/workspace
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/grpc/warehouse.proto"

git -C "$ROOT" diff --quiet -- "$TARGET" || { echo "Target already changed: $TARGET" >&2; exit 1; }
git -C "$ROOT" diff --cached --quiet -- "$TARGET" || { echo "Target is staged: $TARGET" >&2; exit 1; }

sed -i 's/int64 order_id = 1;/string order_id = 1;/g' "$TARGET"

echo "Changed gRPC: order_id is now string instead of int64."
