#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

restore_spec() {
  target=$1
  git -C "$ROOT" restore --source=HEAD --worktree --staged -- "$target"
  echo "Restored $target from HEAD."
}

case "${1:-}" in
  "")
    restore_spec bcc-enterprise-demo/specs/baseline/openapi/orders.yaml
    restore_spec bcc-enterprise-demo/specs/baseline/graphql/orders.graphqls
    restore_spec bcc-enterprise-demo/specs/baseline/grpc/warehouse.proto
    restore_spec bcc-enterprise-demo/specs/baseline/asyncapi/shipping-events.yaml
    ;;
  openapi)
    restore_spec bcc-enterprise-demo/specs/baseline/openapi/orders.yaml
    ;;
  graphql)
    restore_spec bcc-enterprise-demo/specs/baseline/graphql/orders.graphqls
    ;;
  grpc)
    restore_spec bcc-enterprise-demo/specs/baseline/grpc/warehouse.proto
    ;;
  asyncapi)
    restore_spec bcc-enterprise-demo/specs/baseline/asyncapi/shipping-events.yaml
    ;;
  *)
    echo "Usage: cleanup.sh [openapi|graphql|grpc|asyncapi]" >&2
    exit 2
    ;;
esac
