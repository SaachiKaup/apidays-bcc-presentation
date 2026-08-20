#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

sh "$SCRIPT_DIR/clean_slate.sh"
sh "$SCRIPT_DIR/clean_baseline.sh"
