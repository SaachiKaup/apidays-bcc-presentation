#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEMO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(CDPATH= cd -- "$DEMO_ROOT/.." && pwd)
TARGET=${1:?Usage: specmatic-bcc.sh <repository-relative-target-path>}

rm -rf "$REPO_ROOT/build" "$DEMO_ROOT/build"

echo "Running:"
echo "docker run --rm -v $REPO_ROOT:/usr/src/app specmatic/enterprise backward-compatibility-check --base-branch main --target-path $TARGET"
echo

docker run --rm \
  -v "$REPO_ROOT:/usr/src/app" \
  specmatic/enterprise \
  backward-compatibility-check \
  --base-branch main \
  --target-path "$TARGET"
