#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEMO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(CDPATH= cd -- "$DEMO_ROOT/.." && pwd)
TARGET="bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml"
CHANGE="--show-menu"

case "${1:-}" in
  "") ;;
  --add-size|--add-offset|--async-create|--uuid-order-id|--replace-status|--add-updates|--all-breaking|--all-compatible)
    CHANGE=$1 ;;
  customer-orders|openapi)
    shift
    [ "$#" -gt 0 ] && CHANGE=$1 ;;
  *) echo "Usage: $0 [openapi|customer-orders] [change flag]" >&2; exit 2 ;;
esac

sh "$DEMO_ROOT/scripts/customer_orders.sh" "$CHANGE"
rm -rf "$REPO_ROOT/build" "$DEMO_ROOT/build"

echo
echo "Running OpenAPI BCC..."
set +e
sh "$DEMO_ROOT/scripts/specmatic-bcc.sh" "$TARGET"
STATUS=$?
set -e

if [ -d "$REPO_ROOT/build" ]; then
  mv "$REPO_ROOT/build" "$DEMO_ROOT/build"
fi

printf "Clean up the change? [Y/n] "
read -r answer
case "$answer" in
  n|N|no|NO) echo "Change left in the working tree." ;;
  *) sh "$DEMO_ROOT/scripts/cleanup.sh" customer-orders ;;
esac
exit "$STATUS"
