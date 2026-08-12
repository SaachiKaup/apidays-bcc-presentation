#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEMO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

cd "$DEMO_ROOT"

DEMO_PARENT=$(git rev-parse HEAD)
DEMO_COMMIT_CREATED=false

printf "Apply and commit the optional size parameter? [Y/n] "
read -r answer
case "$answer" in
  n|N|no|NO|No)
    echo "Skipped optional size parameter."
    ;;
  *)
    ./scripts/customer_orders.sh --add-size
    git add specs/baseline/openapi/customer_orders.yaml
    git commit -m "temp: added optional order page size"
    DEMO_COMMIT_CREATED=true
    ;;
esac

printf "Apply and commit the mandatory offset parameter? [Y/n] "
read -r answer
case "$answer" in
  n|N|no|NO|No)
    echo "Skipped mandatory offset parameter."
    ;;
  *)
    ./scripts/customer_orders.sh --add-offset
    git add specs/baseline/openapi/customer_orders.yaml
    LIMIT_STATUS=0
    git commit -m "temp: added mandatory order offset" || LIMIT_STATUS=$?
    if [ "$LIMIT_STATUS" -eq 0 ]; then
      echo "Unexpected result: the mandatory offset commit was allowed." >&2
      exit 1
    fi
    echo "The mandatory offset commit was blocked by backward compatibility checking."
    ;;
esac

printf "Undo the demonstration commit and clean up the specifications? [Y/n] "
read -r answer
case "$answer" in
  n|N|no|NO|No)
    echo "Leaving the demonstration changes in place."
    ;;
  *)
    if [ "$DEMO_COMMIT_CREATED" = true ]; then
      git reset --soft "$DEMO_PARENT"
    fi
    ./scripts/cleanup.sh
    echo "Demonstration commit and specification changes were restored."
    ;;
esac
