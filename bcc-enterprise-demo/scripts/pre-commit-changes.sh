#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEMO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

cd "$DEMO_ROOT"

DEMO_PARENT=$(git rev-parse HEAD)
DEMO_COMMIT_CREATED=false

printf "Apply and commit the optional skip parameter? [Y/n] "
read -r answer
case "$answer" in
  n|N|no|NO|No)
    echo "Skipped optional skip parameter."
    ;;
  *)
    ./scripts/openapi_change.sh --add-skip
    git add specs/baseline/openapi/orders.yaml
    git commit -m "temp: added optional skip param"
    DEMO_COMMIT_CREATED=true
    ;;
esac

printf "Apply and commit the mandatory limit parameter? [Y/n] "
read -r answer
case "$answer" in
  n|N|no|NO|No)
    echo "Skipped mandatory limit parameter."
    ;;
  *)
    ./scripts/openapi_change.sh --add-limit
    git add specs/baseline/openapi/orders.yaml
    LIMIT_STATUS=0
    git commit -m "temp: added mandatory limit param" || LIMIT_STATUS=$?
    if [ "$LIMIT_STATUS" -eq 0 ]; then
      echo "Unexpected result: the mandatory limit commit was allowed." >&2
      exit 1
    fi
    echo "The mandatory limit commit was blocked by backward compatibility checking."
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
