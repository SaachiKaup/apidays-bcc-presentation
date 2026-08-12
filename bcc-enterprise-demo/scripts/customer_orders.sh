#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml"
MODE=menu

case "${1:-}" in
  --add-size) MODE=size ;;
  --add-offset) MODE=offset ;;
  --async-create) MODE=async ;;
  --uuid-order-id) MODE=uuid ;;
  --replace-status) MODE=replace_status ;;
  --add-updates) MODE=updates ;;
  --all-breaking) MODE=all_breaking ;;
  --all-compatible) MODE=all_compatible ;;
  --show-menu) MODE=menu ;;
  "") ;;
  *) echo "Usage: $0 [--add-size|--add-offset|--async-create|--uuid-order-id|--replace-status|--add-updates|--all-breaking|--all-compatible|--show-menu]" >&2; exit 2 ;;
esac

if [ "$MODE" = menu ]; then
  echo "Which provider change would you like to demonstrate?"
  echo "1) Add optional size to GET /orders (COMPATIBLE)"
  echo "2) Make offset mandatory on GET /orders (INCOMPATIBLE)"
  echo "3) Change POST /orders from 201 to 202 (INCOMPATIBLE)"
  echo "4) Change orderId from integer to UUID (INCOMPATIBLE)"
  echo "5) Replace status with an updates array (INCOMPATIBLE)"
  echo "6) Add updates while preserving status (COMPATIBLE)"
  echo "7) Apply all breaking changes"
  printf "Choose 1-7: "
  read -r choice
  case "$choice" in
    1) MODE=size ;; 2) MODE=offset ;; 3) MODE=async ;; 4) MODE=uuid ;;
    5) MODE=replace_status ;; 6) MODE=updates ;; 7) MODE=all_breaking ;;
    *) echo "Invalid choice" >&2; exit 2 ;;
  esac
fi

edit() {
  awk "$@" "$TARGET" > "$TARGET.tmp"
  mv "$TARGET.tmp" "$TARGET"
}

add_page_parameter() {
  name=$1
  required=$2
  default=${3:-}
  if grep -q "^        - name: $name$" "$TARGET"; then
    echo "Customer Orders: $name is already present; leaving it unchanged."
    return
  fi
  edit -v name="$name" -v required="$required" -v default="$default" '
    /^  \/orders:$/ { in_orders=1 }
    /^  \/orders\/\{orderId\}:$/ { in_orders=0 }
    in_orders && /^    post:$/ { in_orders=0 }
    in_orders && /^      responses:$/ {
      print "        - name: " name
      print "          in: query"
      print "          required: " required
      print "          schema:"
      print "            type: integer"
      if (name == "size") print "            minimum: 1"
      else print "            minimum: 0"
      if (default != "") print "            default: " default
    }
    { print }
  '
  echo "Changed Customer Orders: added $name to GET /orders."
}

change_async_response() {
  if grep -q "^        '202':$" "$TARGET"; then return; fi
  edit '
    /^  \/orders:$/ { in_orders=1 }
    /^  \/orders\/\{orderId\}:$/ { in_orders=0 }
    in_orders && /^        '\''201'\'':$/ { sub("201", "202"); print; next }
    in_orders && /description: Order created$/ { sub("Order created", "Order accepted for background creation") }
    { print }
  '
  echo "Changed Customer Orders: POST /orders now returns 202 Accepted."
}

change_uuid() {
  if grep -q 'format: uuid' "$TARGET"; then return; fi
  edit '
    /^    OrderId:$/ { in_id=1; print; next }
    in_id && /^      type: integer$/ { print "      type: string"; next }
    in_id && /^      format: int64$/ { print "      format: uuid"; next }
    in_id && /^      example:/ { print "      example: 550e8400-e29b-41d4-a716-446655440000"; in_id=0; next }
    in_id && /^    [A-Za-z]/ { in_id=0 }
    { print }
  '
  echo "Changed Customer Orders: orderId now uses UUID values."
}

replace_status() {
  if grep -A2 '^    OrderStatus:$' "$TARGET" | grep -q 'type: array'; then return; fi
  edit '
    /^    OrderStatus:$/ {
      print
      print "      type: array"
      print "      items:"
      print "        $ref: '\''#/components/schemas/OrderUpdate'\''"
      in_status=1
      next
    }
    in_status && /^    OrderStatusCode:$/ { in_status=0; print; next }
    !in_status { print }
  '
  if ! grep -q '^    OrderUpdate:$' "$TARGET"; then
    edit '
      /^    Problem:$/ {
        print "    OrderUpdate:"
        print "      type: object"
        print "      required: [updatedAt, reason]"
        print "      properties:"
        print "        code:"
        print "          type: string"
        print "          enum: [PENDING, ACCEPTED, SHIPPED, DELIVERED, CANCELLED]"
        print "        reason:"
        print "          type: string"
        print "        updatedAt:"
        print "          type: string"
        print "          format: date-time"
      }
      { print }
    '
  fi
  echo "Changed Customer Orders: status is now an array of order updates."
}

add_updates() {
  if grep -q '^        updates:$' "$TARGET"; then return; fi
  edit '
    /^    Order:$/ { in_order=1 }
    in_order && /^        total:$/ {
      print "        updates:"
      print "          type: array"
      print "          items:"
      print "            $ref: '\''#/components/schemas/OrderUpdate'\''"
    }
    /^    OrderStatusCode:$/ && in_order { in_order=0 }
    { print }
  '
  if ! grep -q '^    OrderUpdate:$' "$TARGET"; then
    edit '
      /^    Problem:$/ {
        print "    OrderUpdate:"
        print "      type: object"
        print "      required: [updatedAt, reason]"
        print "      properties:"
        print "        code:"
        print "          type: string"
        print "          enum: [PENDING, ACCEPTED, SHIPPED, DELIVERED, CANCELLED]"
        print "        reason:"
        print "          type: string"
        print "        updatedAt:"
        print "          type: string"
        print "          format: date-time"
      }
      { print }
    '
  fi
  echo "Changed Customer Orders: added optional updates while preserving status."
}

case "$MODE" in
  size) add_page_parameter size false 20 ;;
  offset) add_page_parameter offset true ;;
  async) change_async_response ;;
  uuid) change_uuid ;;
  replace_status) replace_status ;;
  updates) add_updates ;;
  all_breaking)
    add_page_parameter size false 20
    add_page_parameter offset true
    change_async_response
    change_uuid
    replace_status
    ;;
  all_compatible)
    add_page_parameter size false 20
    add_page_parameter offset false 0
    add_updates
    ;;
esac
