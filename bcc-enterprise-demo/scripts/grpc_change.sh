#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/grpc/warehouse.proto"

git -C "$ROOT" diff --quiet -- "$TARGET" || { echo "Target already changed: $TARGET" >&2; exit 1; }
git -C "$ROOT" diff --cached --quiet -- "$TARGET" || { echo "Target is staged: $TARGET" >&2; exit 1; }

if [ "$(uname -s)" = "Darwin" ]; then
  sed -i '' '/^message Order {/,/^}/ s/int64 order_id = 1;/string order_id = 1; \/\/ e.g. "EU-XYZ123"/' "$TARGET"
else
  sed -i '/^message Order {/,/^}/ s/int64 order_id = 1;/string order_id = 1; \/\/ e.g. "EU-XYZ123"/' "$TARGET"
fi

echo "Changed gRPC: the Order response now supports string IDs such as EU-XYZ123."
