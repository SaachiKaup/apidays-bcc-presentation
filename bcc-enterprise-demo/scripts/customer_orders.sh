#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/openapi/customer_orders.yaml"
MODE=menu

case "${1:-}" in
  --add-size) MODE=size ;;
  --add-offset) MODE=offset ;;
  --change-status|--change-status-code) MODE=status_code ;;
  --global-id|--change-id) MODE=global_id ;;
  --richer-status) MODE=richer_status ;;
  --all) MODE=all ;;
  --show-menu) MODE=menu ;;
  "") ;;
  *)
    echo "Usage: $0 [--add-size|--add-offset|--change-status|--global-id|--richer-status|--all|--show-menu]" >&2
    exit 2
    ;;
esac

if [ "$MODE" = menu ]; then
  echo "Which customer-orders change would you like to demonstrate?"
  echo "1) Add optional size — larger result sets need client-controlled page size (COMPATIBLE)"
  echo "2) Make offset mandatory — every request must declare its page position (INCOMPATIBLE)"
  echo "3) Change 404 to 422 — standardize order-not-found handling (INCOMPATIBLE)"
  echo "4) Change numeric IDs to global string IDs — support international identifiers (INCOMPATIBLE)"
  echo "5) Make status a richer object — expose code, reason, and update time (INCOMPATIBLE)"
  echo "6) Apply all five changes"
  printf "Choose 1-6: "
  read -r choice
  case "$choice" in
    1) MODE=size ;;
    2) MODE=offset ;;
    3) MODE=status_code ;;
    4) MODE=global_id ;;
    5) MODE=richer_status ;;
    6) MODE=all ;;
    *) echo "Invalid choice" >&2; exit 2 ;;
  esac
fi

write_temp() {
  awk "$@" "$TARGET" > "$TARGET.tmp"
  mv "$TARGET.tmp" "$TARGET"
}

add_parameter() {
  parameter_name=$1
  parameter_required=$2
  parameter_minimum=$3
  parameter_default=${4:-}

  if grep -q "^        - name: $parameter_name$" "$TARGET"; then
    echo "Customer Orders: $parameter_name is already present; leaving it unchanged."
    return 0
  fi

  write_temp -v parameter_name="$parameter_name" \
    -v parameter_required="$parameter_required" \
    -v parameter_minimum="$parameter_minimum" \
    -v parameter_default="$parameter_default" '
    /^  \/orders:$/ { in_list_orders=1 }
    /^  \/orders\/\{orderId\}:$/ { in_list_orders=0 }
    /^      responses:/ && in_list_orders {
      print "        - name: " parameter_name
      print "          in: query"
      print "          required: " parameter_required
      print "          schema:"
      print "            type: integer"
      print "            minimum: " parameter_minimum
      if (parameter_default != "") print "            default: " parameter_default
      in_list_orders=0
    }
    { print }
  '

  if ! grep -q "^        - name: $parameter_name$" "$TARGET"; then
    echo "Could not add the $parameter_name parameter." >&2
    exit 1
  fi
}

change_status_code() {
  if grep -v '^[[:space:]]*#' "$TARGET" | grep -q "^        '422':$"; then
    echo "Customer Orders: the order-not-found response is already 422; leaving it unchanged."
    return 0
  fi
  if ! grep -v '^[[:space:]]*#' "$TARGET" | grep -q "^        '404':$"; then
    echo "Could not find the baseline 404 response." >&2
    exit 1
  fi
  if [ "$(uname -s)" = "Darwin" ]; then
    sed -i '' "s/^        '404':$/        '422':/" "$TARGET"
  else
    sed -i "s/^        '404':$/        '422':/" "$TARGET"
  fi
}

change_global_id() {
  if grep -v '^[[:space:]]*#' "$TARGET" | grep -q "example: EU-XYZ123"; then
    echo "Customer Orders: IDs are already global strings; leaving them unchanged."
    return 0
  fi
  if ! grep -v '^[[:space:]]*#' "$TARGET" | grep -q "^    OrderId:$"; then
    echo "Could not find the shared numeric OrderId schema in the baseline spec." >&2
    exit 1
  fi
  write_temp '
    /^  schemas:$/ { in_schemas=1 }
    in_schemas && /^    OrderId:$/ { in_order_id=1; print; next }
    in_order_id && /^      type: integer$/ { print "      type: string"; next }
    in_order_id && /^      format: int64$/ { next }
    in_order_id && /^      example: 202600123$/ { print "      example: EU-XYZ123"; in_order_id=0; next }
    in_order_id && /^    [A-Za-z][A-Za-z0-9]*:/ { in_order_id=0 }
    { print }
  '
}

change_richer_status() {
  if grep -q '^    OrderStatus:$' "$TARGET" && awk '
    /^    OrderStatus:$/ { in_status=1; next }
    in_status && /^    OrderStatusCode:/ { exit }
    in_status && /^      type: object$/ { found=1 }
    END { exit(found ? 0 : 1) }
  ' "$TARGET"; then
    echo "Customer Orders: status is already a structured object; leaving it unchanged."
    return 0
  fi
  write_temp '
    /^    OrderStatus:$/ {
      print
      print "      type: object"
      print "      required: [code, reason, updatedAt]"
      print "      properties:"
      print "        code:"
      print "          type: string"
      print "          enum: [PENDING, ACCEPTED, SHIPPED, DELIVERED, CANCELLED]"
      print "        reason:"
      print "          type: string"
      print "        updatedAt:"
      print "          type: string"
      print "          format: date-time"
      in_status=1
      next
    }
    in_status && /^    OrderStatusCode:$/ { in_status=0; print; next }
    !in_status { print }
  '
}

case "$MODE" in
  size)
    add_parameter size false 1 20
    echo "Changed Customer Orders: added optional size for client-controlled page size."
    ;;
  offset)
    add_parameter offset true 0
    echo "Changed Customer Orders: added mandatory offset for explicit page position."
    ;;
  status_code)
    change_status_code
    echo "Changed Customer Orders: order-not-found responses now use 422 instead of 404."
    ;;
  global_id)
    change_global_id
    echo "Changed Customer Orders: numeric IDs now support global values such as EU-XYZ123."
    ;;
  richer_status)
    change_richer_status
    echo "Changed Customer Orders: status now includes code, reason, and updatedAt."
    ;;
  all)
    add_parameter size false 1 20
    add_parameter offset true 0
    change_status_code
    change_global_id
    change_richer_status
    echo "Changed Customer Orders: applied pagination, error, ID, and richer-status changes."
    ;;
esac
