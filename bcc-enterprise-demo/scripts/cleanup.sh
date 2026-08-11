#!/bin/sh

set -eu

ROOT=/workspace

case "${1:-}" in
  openapi)
    TARGET=bcc-enterprise-demo/specs/baseline/openapi/orders.yaml
    ;;
  graphql)
    TARGET=bcc-enterprise-demo/specs/baseline/graphql/orders.graphqls
    ;;
  grpc)
    TARGET=bcc-enterprise-demo/specs/baseline/grpc/warehouse.proto
    ;;
  asyncapi)
    TARGET=bcc-enterprise-demo/specs/baseline/asyncapi/shipping-events.yaml
    ;;
  *)
    echo "Usage: cleanup.sh {openapi|graphql|grpc|asyncapi}" >&2
    exit 2
    ;;
esac

git -C "$ROOT" restore --source=HEAD --worktree --staged -- "$TARGET"
echo "Restored $TARGET from HEAD."
