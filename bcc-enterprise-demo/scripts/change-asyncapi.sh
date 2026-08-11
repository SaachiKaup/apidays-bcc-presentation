#!/bin/sh

set -eu

ROOT=/workspace
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/asyncapi/shipping-events.yaml"

git -C "$ROOT" diff --quiet -- "$TARGET" || { echo "Target already changed: $TARGET" >&2; exit 1; }
git -C "$ROOT" diff --cached --quiet -- "$TARGET" || { echo "Target is staged: $TARGET" >&2; exit 1; }

awk '
  /^        status:$/ {
    print
    print "          type: object"
    print "          required: [code, reason, updatedAt]"
    print "          properties:"
    print "            code:"
    print "              type: string"
    print "              enum: [PACKED, SHIPPED, DELIVERED, RETURNED]"
    print "            reason:"
    print "              type: string"
    print "            updatedAt:"
    print "              type: string"
    print "              format: date-time"
    skip=1
    next
  }
  skip && /^        trackingNumber:/ { skip=0; print; next }
  !skip { print }
' "$TARGET" > "$TARGET.tmp"
mv "$TARGET.tmp" "$TARGET"

echo "Changed AsyncAPI: status is now a structured object."
