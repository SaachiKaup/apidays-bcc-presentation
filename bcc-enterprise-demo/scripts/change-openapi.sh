#!/bin/sh

set -eu

ROOT=/workspace
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/openapi/orders.yaml"

git -C "$ROOT" diff --quiet -- "$TARGET" || { echo "Target already changed: $TARGET" >&2; exit 1; }
git -C "$ROOT" diff --cached --quiet -- "$TARGET" || { echo "Target is staged: $TARGET" >&2; exit 1; }

# Add pagination to the order-history operation, but make `limit` mandatory
# so this proposed release demonstrates a request-parameter incompatibility.
awk '
  /parameters\/Status/ {
    print
    print "        - $ref: \047#/components/parameters/Skip\047"
    print "        - $ref: \047#/components/parameters/Limit\047"
    next
  }

  /^    OrderId:/ {
    print "    Skip:"
    print "      name: skip"
    print "      in: query"
    print "      required: false"
    print "      schema:"
    print "        type: integer"
    print "        minimum: 0"
    print "        default: 0"
    print "    Limit:"
    print "      name: limit"
    print "      in: query"
    print "      required: true"
    print "      schema:"
    print "        type: integer"
    print "        minimum: 1"
    print "        default: 20"
  }

  { print }
' "$TARGET" > "$TARGET.tmp"
mv "$TARGET.tmp" "$TARGET"

# Also change 404 to 422 to demonstrate status-code incompatibility.
sed -i "s/^        '404':$/        '422':/" "$TARGET"

echo "Changed OpenAPI: limit is mandatory and 404 is now 422."
