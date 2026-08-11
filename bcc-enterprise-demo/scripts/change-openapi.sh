#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/openapi/orders.yaml"

git -C "$ROOT" diff --quiet -- "$TARGET" || { echo "Target already changed: $TARGET" >&2; exit 1; }
git -C "$ROOT" diff --cached --quiet -- "$TARGET" || { echo "Target is staged: $TARGET" >&2; exit 1; }

# Add pagination to the order-history operation, but make `limit` mandatory
# so this proposed release demonstrates a request-parameter incompatibility.
awk '
  /^        - name: status$/ {
    print
    in_list_parameters=true
    next
  }

  in_list_parameters && /^      responses:/ {
    print "        - name: skip"
    print "          in: query"
    print "          required: false"
    print "          schema:"
    print "            type: integer"
    print "            minimum: 0"
    print "            default: 0"
    print "        - name: limit"
    print "          in: query"
    print "          required: true"
    print "          schema:"
    print "            type: integer"
    print "            minimum: 1"
    print "            default: 20"
    in_list_parameters=false
    print
    next
  }

  { print }
' "$TARGET" > "$TARGET.tmp"
mv "$TARGET.tmp" "$TARGET"

# Also change 404 to 422 to demonstrate status-code incompatibility.
if [ "$(uname -s)" = "Darwin" ]; then
  sed -i '' "s/^        '404':$/        '422':/" "$TARGET"
else
  sed -i "s/^        '404':$/        '422':/" "$TARGET"
fi

echo "Changed OpenAPI: limit is mandatory and 404 is now 422."
