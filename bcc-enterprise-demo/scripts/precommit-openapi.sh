#!/bin/sh

set -eu

REPO_ROOT=$(git rev-parse --show-toplevel)
DEMO_ROOT="$REPO_ROOT/bcc-enterprise-demo"
TARGET="bcc-enterprise-demo/specs/baseline/openapi"

# Do not run the check for unrelated commits.
STAGED_TARGET=false
while IFS= read -r file; do
  case "$file" in
    "$TARGET"/*)
      STAGED_TARGET=true
      break
      ;;
  esac
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
BASE_COMMIT=$(git -C "$REPO_ROOT" rev-parse main)
git -C "$SNAPSHOT" update-ref refs/heads/main "$BASE_COMMIT"

while IFS= read -r file; do
  case "$file" in
    "$TARGET"/*)
      mkdir -p "$SNAPSHOT/$(dirname "$file")"
      git -C "$REPO_ROOT" show ":$file" > "$SNAPSHOT/$file"
      ;;
  esac
done <<EOF
$(git diff --cached --name-only --diff-filter=ACM)
EOF

echo "Running:"
echo "docker run --rm -v $SNAPSHOT:/usr/src/app specmatic/enterprise backward-compatibility-check --base-branch main --target-path $TARGET"
echo

set +e
docker run --rm \
  -v "$SNAPSHOT:/usr/src/app" \
  specmatic/enterprise \
  backward-compatibility-check \
  --base-branch main \
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
