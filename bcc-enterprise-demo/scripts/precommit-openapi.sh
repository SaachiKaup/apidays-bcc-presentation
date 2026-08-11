#!/bin/sh

set -eu

REPO_ROOT=$(git rev-parse --show-toplevel)
DEMO_ROOT="$REPO_ROOT/bcc-enterprise-demo"
TARGET="bcc-enterprise-demo/specs/baseline/openapi/orders.yaml"

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

set +e
docker compose \
  -f "$DEMO_ROOT/docker-compose.yml" \
  run --rm --entrypoint specmatic bcc \
  backward-compatibility-check \
  --base-branch main \
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
