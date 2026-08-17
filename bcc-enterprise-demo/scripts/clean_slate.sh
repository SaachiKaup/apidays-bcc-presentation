#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEMO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(CDPATH= cd -- "$DEMO_ROOT/.." && pwd)

if [ -d "$REPO_ROOT/build" ]; then
  rm -rf "$REPO_ROOT/build"
fi

if [ -d "$DEMO_ROOT/build" ]; then
  rm -rf "$DEMO_ROOT/build"
fi
