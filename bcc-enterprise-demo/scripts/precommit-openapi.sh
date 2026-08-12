#!/bin/sh

set -eu

REPO_ROOT=$(git rev-parse --show-toplevel)
DEMO_ROOT="$REPO_ROOT/bcc-enterprise-demo"
TARGET="bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml"

# Do not run the check for unrelated commits.
STAGED_TARGET=false
while IFS= read -r file; do
  if [ "$file" = "$TARGET" ]; then
    STAGED_TARGET=true
    break
  fi
done <<EOF
$(git diff --cached --name-only --diff-filter=ACM)
EOF

if [ "$STAGED_TARGET" != true ]; then
  exit 0
fi

echo "Running OpenAPI backward compatibility check before commit..."
echo

# Git holds .git/index.lock while this hook is running. Create an isolated
# repository snapshot so Specmatic can use Git without competing with commit.
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/specmatic-bcc-hook.XXXXXX")
SNAPSHOT="$TEMP_ROOT/repository"
cleanup() {
  rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT HUP INT TERM

git clone --quiet --no-local "$REPO_ROOT" "$SNAPSHOT"
mkdir -p "$(dirname "$SNAPSHOT/$TARGET")"
git -C "$REPO_ROOT" show ":$TARGET" > "$SNAPSHOT/$TARGET"

LICENSE="$DEMO_ROOT/license.txt"
if [ ! -f "$LICENSE" ]; then
  echo "Specmatic license not found: $LICENSE" >&2
  exit 1
fi

echo "Running:"
echo "docker run --rm -v $SNAPSHOT:/workspace -v $LICENSE:/specmatic/specmatic-license.txt:ro -w /workspace -e SPECMATIC_LICENSE_PATH=/specmatic/specmatic-license.txt specmatic/enterprise:latest backward-compatibility-check --base-branch origin/main --repo-dir /workspace --target-path $TARGET"
echo

set +e
docker run --rm \
  -v "$SNAPSHOT:/workspace" \
  -v "$LICENSE:/specmatic/specmatic-license.txt:ro" \
  -w /workspace \
  -e SPECMATIC_LICENSE_PATH=/specmatic/specmatic-license.txt \
  specmatic/enterprise:latest \
  backward-compatibility-check \
  --base-branch origin/main \
  --repo-dir /workspace \
  --target-path "$TARGET"
STATUS=$?
set -e

if [ "$STATUS" -ne 0 ]; then
  echo
  echo "Commit blocked: the OpenAPI specification is not backward compatible."
  echo "Restore or redesign the change, then stage the specification again."
  exit "$STATUS"
fi

echo
echo "OpenAPI backward compatibility check passed. Commit allowed."
