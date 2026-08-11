#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
DEMO_ROOT="$REPO_ROOT/bcc-enterprise-demo"
YES=false
SPEC_TYPE="${1:-}"
OPENAPI_OPTION=""

if [ -n "$SPEC_TYPE" ]; then
  shift
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --yes)
      YES=true
      ;;
    --add-skip|--add-limit|--change-status|--change-status-code|--all|--show-menu)
      OPENAPI_OPTION="$1"
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

if [ -z "$SPEC_TYPE" ]; then
  echo "Which spec type should be demonstrated?"
  echo "1) openapi"
  echo "2) graphql"
  echo "3) grpc"
  echo "4) asyncapi"
  printf "Choose 1-4: "
  read -r choice
  case "$choice" in
    1) SPEC_TYPE=openapi ;;
    2) SPEC_TYPE=graphql ;;
    3) SPEC_TYPE=grpc ;;
    4) SPEC_TYPE=asyncapi ;;
    *) echo "Invalid choice" >&2; exit 2 ;;
  esac
fi

case "$SPEC_TYPE" in
  openapi)
    CHANGE_SCRIPT="$DEMO_ROOT/scripts/openapi_change.sh"
    TARGET="bcc-enterprise-demo/specs/baseline/openapi/orders.yaml"
    ;;
  graphql)
    CHANGE_SCRIPT="$DEMO_ROOT/scripts/graphql_change.sh"
    TARGET="bcc-enterprise-demo/specs/baseline/graphql/orders.graphqls"
    ;;
  grpc)
    CHANGE_SCRIPT="$DEMO_ROOT/scripts/grpc_change.sh"
    TARGET="bcc-enterprise-demo/specs/baseline/grpc/warehouse.proto"
    ;;
  asyncapi)
    CHANGE_SCRIPT="$DEMO_ROOT/scripts/asyncapi_change.sh"
    TARGET="bcc-enterprise-demo/specs/baseline/asyncapi/shipping-events.yaml"
    ;;
  *)
    echo "Usage: ./scripts/run-bcc.sh [openapi|graphql|grpc|asyncapi] [OpenAPI change flag] [--yes]" >&2
    exit 2
    ;;
esac

if ! git -C "$REPO_ROOT" diff --quiet -- "$TARGET" || \
   ! git -C "$REPO_ROOT" diff --cached --quiet -- "$TARGET"; then
  echo "The target spec already has changes: $TARGET" >&2
  echo "Clean it before starting another demonstration." >&2
  exit 1
fi

if ! git -C "$REPO_ROOT" ls-files --error-unmatch "$TARGET" >/dev/null 2>&1; then
  echo "The baseline spec is not committed in the current Git branch: $TARGET" >&2
  exit 1
fi

echo "Applying the $SPEC_TYPE breaking change..."
if [ "$SPEC_TYPE" = "openapi" ] && [ -n "$OPENAPI_OPTION" ]; then
  sh "$CHANGE_SCRIPT" "$OPENAPI_OPTION"
elif [ "$SPEC_TYPE" = "openapi" ] && [ "$YES" != true ]; then
  sh "$CHANGE_SCRIPT" --show-menu
else
  sh "$CHANGE_SCRIPT"
fi

RUN_BCC=y
if [ "$YES" != true ]; then
  printf "Run the Specmatic BCC check now? [Y/n] "
  read -r RUN_BCC
fi

if [ "$RUN_BCC" = "n" ] || [ "$RUN_BCC" = "N" ]; then
  echo "Change left in the working tree."
  echo "Run: docker compose -f $DEMO_ROOT/docker-compose.yml run --rm --entrypoint specmatic bcc backward-compatibility-check --base-branch main --repo-dir /workspace --target-path $TARGET"
  echo "Clean up: docker compose run --rm --entrypoint sh bcc /workspace/bcc-enterprise-demo/scripts/cleanup.sh $SPEC_TYPE"
  exit 0
fi

echo
echo "Running:"
echo "docker compose -f $DEMO_ROOT/docker-compose.yml run --rm --entrypoint specmatic bcc backward-compatibility-check --base-branch main --repo-dir /workspace --target-path $TARGET"
echo

# Remove reports from an earlier run so they cannot be mistaken for changed
# specifications by the repository-wide compatibility check.
rm -rf "$DEMO_ROOT/build"

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

echo
CLEANUP=y
if [ "$YES" != true ]; then
  printf "Clean up the $SPEC_TYPE change? [Y/n] "
  read -r CLEANUP
fi

if [ "$CLEANUP" = "n" ] || [ "$CLEANUP" = "N" ]; then
  echo "Change left in the working tree."
  echo "Clean up: docker compose run --rm --entrypoint sh bcc /workspace/bcc-enterprise-demo/scripts/cleanup.sh $SPEC_TYPE"
else
  sh "$DEMO_ROOT/scripts/cleanup.sh" "$SPEC_TYPE"
fi

exit "$BCC_STATUS"
