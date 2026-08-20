#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

git -C "$REPO_ROOT" restore --source=HEAD --worktree --staged -- \
  bcc-enterprise-demo/specs/baseline/openapi \
  bcc-enterprise-demo/specs/baseline/graphql \
  bcc-enterprise-demo/specs/baseline/grpc \
  bcc-enterprise-demo/specs/baseline/asyncapi
