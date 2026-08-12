#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEMO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(CDPATH= cd -- "$DEMO_ROOT/.." && pwd)
TARGET=${1:?Usage: specmatic-bcc.sh <repository-relative-target-path>}

LICENSE="$DEMO_ROOT/license.txt"
if [ ! -f "$LICENSE" ]; then
  echo "Specmatic license not found: $LICENSE" >&2
  exit 1
fi

rm -rf "$REPO_ROOT/build" "$DEMO_ROOT/build"

echo "Running:"
echo "docker run --rm -v $REPO_ROOT:/workspace -v $LICENSE:/specmatic/specmatic-license.txt:ro -w /workspace -e SPECMATIC_LICENSE_PATH=/specmatic/specmatic-license.txt specmatic/enterprise:latest backward-compatibility-check --base-branch main --repo-dir /workspace --target-path $TARGET"
echo

docker run --rm \
  -v "$REPO_ROOT:/workspace" \
  -v "$LICENSE:/specmatic/specmatic-license.txt:ro" \
  -w /workspace \
  -e SPECMATIC_LICENSE_PATH=/specmatic/specmatic-license.txt \
  specmatic/enterprise:latest \
  backward-compatibility-check \
  --base-branch main \
  --repo-dir /workspace \
  --target-path "$TARGET"
