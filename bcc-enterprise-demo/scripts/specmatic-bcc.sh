#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEMO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(CDPATH= cd -- "$DEMO_ROOT/.." && pwd)
TARGET=${1:?Usage: specmatic-bcc.sh <repository-relative-target-path>}

rm -rf "$REPO_ROOT/build" "$DEMO_ROOT/build"

echo "Running:"
case "$TARGET" in
  */openapi|*/openapi/*)
    echo "docker run --rm -v $REPO_ROOT:/usr/src/app specmatic/enterprise backward-compatibility-check --strict --base-branch main --target-path $TARGET"
    echo

    docker run --rm \
      -v "$REPO_ROOT:/usr/src/app" \
      specmatic/enterprise \
      backward-compatibility-check \
      --base-branch main \
      --target-path "$TARGET"
    ;;
  *)
    LICENSE="$DEMO_ROOT/enterprise-license.txt"
    if [ ! -f "$LICENSE" ]; then
      echo "Enterprise license not found: $LICENSE" >&2
      exit 1
    fi

    echo "docker run --rm -v $REPO_ROOT:/usr/src/app -v $LICENSE:/specmatic/specmatic-license.txt:ro -e SPECMATIC_LICENSE_PATH=/specmatic/specmatic-license.txt specmatic/enterprise backward-compatibility-check --base-branch main --target-path $TARGET"
    echo

    docker run --rm \
      -v "$REPO_ROOT:/usr/src/app" \
      -v "$LICENSE:/specmatic/specmatic-license.txt:ro" \
      -e SPECMATIC_LICENSE_PATH=/specmatic/specmatic-license.txt \
      specmatic/enterprise \
      backward-compatibility-check \
      --strict \
      --base-branch main \
      --target-path "$TARGET"
    ;;
esac
