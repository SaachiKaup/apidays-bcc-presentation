#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
TARGET="$ROOT/bcc-enterprise-demo/specs/baseline/openapi/orders.yaml"
MODE=all

case "${1:-}" in
  --add-skip)
    MODE=skip
    ;;
  --add-limit)
    MODE=limit
    ;;
  --change-status|--change-status-code)
    MODE=status
    ;;
  --all)
    MODE=all
    ;;
  --show-menu)
  echo "What would you like to change in the OpenAPI spec?"
  echo "1) Add the optional skip parameter"
  echo "2) Add the mandatory limit parameter"
  echo "3) Change the 404 response to 422"
  echo "4) Apply all three changes"
  printf "Choose 1-4: "
  read -r choice
  case "$choice" in
    1) MODE=skip ;;
    2) MODE=limit ;;
    3) MODE=status ;;
    4) MODE=all ;;
    *) echo "Invalid choice" >&2; exit 2 ;;
  esac
  ;;
  "")
    ;;
  *)
  echo "Usage: $0 [--add-skip|--add-limit|--change-status|--change-status-code|--all|--show-menu]" >&2
  exit 2
  ;;
esac

add_parameter() {
  parameter_name=$1
  parameter_required=$2
  parameter_default=$3

  if grep -q "^        - name: $parameter_name$" "$TARGET"; then
    echo "OpenAPI: $parameter_name is already present; leaving it unchanged."
    return 0
  fi

  awk \
    -v parameter_name="$parameter_name" \
    -v parameter_required="$parameter_required" \
    -v parameter_default="$parameter_default" '
    /^        - name: status$/ {
      print
      in_list_parameters=1
      next
    }

    in_list_parameters && /^      responses:/ {
      print "        - name: " parameter_name
      print "          in: query"
      print "          required: " parameter_required
      print "          schema:"
      print "            type: integer"
      if (parameter_name == "skip") {
        print "            minimum: 0"
      } else {
        print "            minimum: 1"
      }
      print "            default: " parameter_default
      in_list_parameters=0
      print
      next
    }

    { print }
  ' "$TARGET" > "$TARGET.tmp"
  mv "$TARGET.tmp" "$TARGET"

  if ! grep -q "^        - name: $parameter_name$" "$TARGET"; then
    echo "Could not add the $parameter_name parameter." >&2
    exit 1
  fi
}

change_status() {
  if grep -q "^        '422':$" "$TARGET"; then
    echo "OpenAPI: status code is already 422; leaving it unchanged."
    return 0
  fi

  if ! grep -q "^        '404':$" "$TARGET"; then
    echo "Could not find the baseline 404 response." >&2
    exit 1
  fi

  if [ "$(uname -s)" = "Darwin" ]; then
    sed -i '' "s/^        '404':$/        '422':/" "$TARGET"
  else
    sed -i "s/^        '404':$/        '422':/" "$TARGET"
  fi

  if grep -q "^        '404':$" "$TARGET"; then
    echo "Could not change 404 to 422." >&2
    exit 1
  fi
}

case "$MODE" in
  skip)
    add_parameter skip false 0
    echo "Changed OpenAPI: added the optional skip parameter."
    ;;
  limit)
    add_parameter limit true 20
    echo "Changed OpenAPI: added the mandatory limit parameter."
    ;;
  status)
    change_status
    echo "Changed OpenAPI: 404 is now 422."
    ;;
  all)
    add_parameter skip false 0
    add_parameter limit true 20
    change_status
    echo "Changed OpenAPI: added skip, made limit mandatory, and changed 404 to 422."
    ;;
esac
