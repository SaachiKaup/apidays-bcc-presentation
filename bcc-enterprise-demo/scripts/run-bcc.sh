#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
DEMO_ROOT="$REPO_ROOT/bcc-enterprise-demo"
TARGET="bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml"
CHANGE_SCRIPT="$DEMO_ROOT/scripts/customer_orders.sh"
YES=false
CHANGE_OPTION=""
SPEC_TYPE="${1:-}"

if [ -n "$SPEC_TYPE" ]; then
  case "$SPEC_TYPE" in
    --add-size|--add-offset|--change-status|--change-status-code|--global-id|--change-id|--richer-status|--all|--show-menu)
      CHANGE_OPTION="$SPEC_TYPE"
      SPEC_TYPE=customer-orders
      ;;
    customer-orders|customer_orders|openapi)
      shift
      ;;
    *)
      echo "Usage: ./scripts/run-bcc.sh [customer-orders] [change flag] [--yes]" >&2
      exit 2
      ;;
  esac
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --yes) YES=true ;;
    --add-size|--add-offset|--change-status|--change-status-code|--global-id|--change-id|--richer-status|--all|--show-menu)
      CHANGE_OPTION="$1"
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

if [ -z "$SPEC_TYPE" ]; then
  SPEC_TYPE=customer-orders
  echo "Which customer-orders change should be demonstrated?"
  echo "The next menu explains the business reason and expected BCC result."
fi

if ! git -C "$REPO_ROOT" ls-files --error-unmatch "$TARGET" >/dev/null 2>&1; then
  echo "The baseline spec is not committed in the current Git branch: $TARGET" >&2
  exit 1
fi

echo "Applying the customer-orders change..."
if [ -n "$CHANGE_OPTION" ]; then
  sh "$CHANGE_SCRIPT" "$CHANGE_OPTION"
elif [ "$YES" = true ]; then
  sh "$CHANGE_SCRIPT" --all
else
  sh "$CHANGE_SCRIPT" --show-menu
fi

RUN_BCC=y
if [ "$YES" != true ]; then
  printf "Run the Specmatic BCC check now? [Y/n] "
  read -r RUN_BCC
fi

if [ "$RUN_BCC" = "n" ] || [ "$RUN_BCC" = "N" ]; then
  echo "Change left in the working tree."
  echo "Run: docker compose -f $DEMO_ROOT/docker-compose.yml run --rm --entrypoint specmatic bcc backward-compatibility-check --base-branch main --repo-dir /workspace --target-path $TARGET"
  echo "Clean up: ./scripts/cleanup.sh customer-orders"
  exit 0
fi

echo
echo "Running:"
echo "docker compose -f $DEMO_ROOT/docker-compose.yml run --rm --entrypoint specmatic bcc backward-compatibility-check --base-branch main --repo-dir /workspace --target-path $TARGET"
echo

rm -rf "$REPO_ROOT/build" "$DEMO_ROOT/build"

set +e
if [ "${SPECMATIC_IN_CONTAINER:-false}" = "true" ]; then
  specmatic backward-compatibility-check \
    --base-branch main \
    --repo-dir "$REPO_ROOT" \
    --target-path "$TARGET"
else
  docker compose \
    -f "$DEMO_ROOT/docker-compose.yml" \
    run --rm --entrypoint specmatic bcc \
    backward-compatibility-check \
    --base-branch main \
    --repo-dir /workspace \
    --target-path "$TARGET"
fi
BCC_STATUS=$?
set -e

if [ -d "$REPO_ROOT/build" ]; then
  mv "$REPO_ROOT/build" "$DEMO_ROOT/build"
fi

echo
CLEANUP=y
if [ "$YES" != true ]; then
  printf "Clean up the customer-orders change? [Y/n] "
  read -r CLEANUP
fi

if [ "$CLEANUP" = "n" ] || [ "$CLEANUP" = "N" ]; then
  echo "Change left in the working tree."
  echo "Clean up: ./scripts/cleanup.sh customer-orders"
else
  sh "$DEMO_ROOT/scripts/cleanup.sh" customer-orders
fi

exit "$BCC_STATUS"
