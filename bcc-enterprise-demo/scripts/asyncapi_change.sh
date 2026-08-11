#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/asyncapi/shipping-events.yaml"

if awk '
  /^        status:$/ { in_status=1; next }
  in_status && /^        trackingNumber:/ { exit }
  in_status && /^          type: object$/ { found=1 }
  END { exit(found ? 0 : 1) }
' "$TARGET"; then
  echo "AsyncAPI: status is already a structured object; leaving it unchanged."
  exit 0
fi

if ! awk '
  /^        status:$/ { in_status=1; next }
  in_status && /^        trackingNumber:/ { exit }
  in_status && /^          type: string$/ { found=1 }
  END { exit(found ? 0 : 1) }
' "$TARGET"; then
  echo "Could not find the baseline string status field." >&2
  exit 1
fi

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
