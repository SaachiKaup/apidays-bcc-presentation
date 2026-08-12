#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEMO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(CDPATH= cd -- "$DEMO_ROOT/.." && pwd)

case "${1:-}" in
  graphql)
    CHANGE="$DEMO_ROOT/scripts/graphql_change.sh"
    TARGET="bcc-enterprise-demo/specs/baseline/graphql/orders.graphqls"
    ;;
  grpc)
    CHANGE="$DEMO_ROOT/scripts/grpc_change.sh"
    TARGET="bcc-enterprise-demo/specs/baseline/grpc/warehouse.proto"
    ;;
  asyncapi)
    CHANGE="$DEMO_ROOT/scripts/asyncapi_change.sh"
    TARGET="bcc-enterprise-demo/specs/baseline/asyncapi/shipping-events.yaml"
    ;;
  *)
    echo "Usage: $0 [graphql|grpc|asyncapi]" >&2
    exit 2
    ;;
esac

sh "$CHANGE"
rm -rf "$REPO_ROOT/build" "$DEMO_ROOT/build"

set +e
sh "$DEMO_ROOT/scripts/specmatic-bcc.sh" "$TARGET"
STATUS=$?
set -e

echo
printf "Clean up the pre-canned change? [Y/n] "
read -r answer
case "$answer" in
  n|N|no|NO) echo "Change left in the working tree." ;;
  *) sh "$DEMO_ROOT/scripts/cleanup.sh" "$1" ;;
esac
exit "$STATUS"
