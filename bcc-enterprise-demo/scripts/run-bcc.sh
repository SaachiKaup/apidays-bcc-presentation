#!/bin/sh

set -eu

SCENARIO="${1:-breaking}"
DEMO_ROOT=/demo
WORK_REPO=/tmp/bcc-enterprise-demo-repo
REPORT_DIR="$DEMO_ROOT/build/reports/$SCENARIO"

case "$SCENARIO" in
  compatible|breaking|remediated|wip)
    ;;
  ci)
    SCENARIO=breaking
    ;;
  *)
    echo "Usage: docker compose run --rm bcc {compatible|breaking|remediated|wip|ci}" >&2
    exit 2
    ;;
esac

rm -rf "$WORK_REPO"
mkdir -p "$WORK_REPO/specs" "$REPORT_DIR"

cp -R "$DEMO_ROOT/specs/baseline/." "$WORK_REPO/specs/"

git -C "$WORK_REPO" init -q
git -C "$WORK_REPO" config user.email "demo@specmatic.local"
git -C "$WORK_REPO" config user.name "Specmatic BCC Demo"
git -C "$WORK_REPO" add specs
git -C "$WORK_REPO" commit -qm "baseline contract specifications"
git -C "$WORK_REPO" branch -M main

if [ "$SCENARIO" = "wip" ]; then
  cp -R "$DEMO_ROOT/specs/compatible/." "$WORK_REPO/specs/"
  cp "$DEMO_ROOT/specs/breaking/openapi/orders.yaml" "$WORK_REPO/specs/openapi/orders.yaml"
  WIP_OPENAPI="$WORK_REPO/specs/openapi/orders.yaml"
  awk '
    { print }
    /summary: List orders for a customer with mandatory pagination/ {
      print "      tags:"
      print "        - WIP"
    }
  ' "$WIP_OPENAPI" > "$WIP_OPENAPI.tmp"
  mv "$WIP_OPENAPI.tmp" "$WIP_OPENAPI"
elif [ "$SCENARIO" = "remediated" ]; then
  cp -R "$DEMO_ROOT/specs/compatible/." "$WORK_REPO/specs/"
else
  cp -R "$DEMO_ROOT/specs/$SCENARIO/." "$WORK_REPO/specs/"
fi

echo "=== Specmatic Backward Compatibility Demo ==="
echo "Scenario: $SCENARIO"
echo "Baseline: main"
echo "Target:   specs/"
echo

set +e
(
  cd "$WORK_REPO"
  specmatic backward-compatibility-check \
    --repo-dir "$WORK_REPO" \
    --base-branch main \
    --target-path specs
)
STATUS=$?
set -e

if [ -d "$WORK_REPO/build" ]; then
  cp -R "$WORK_REPO/build/." "$REPORT_DIR/"
fi

echo
echo "Reports: $REPORT_DIR"

if [ "$SCENARIO" = "breaking" ]; then
  if [ "$STATUS" -eq 0 ]; then
    echo "ERROR: breaking scenario unexpectedly passed" >&2
    exit 1
  fi
  echo "Expected result: incompatible specifications detected"
  exit 0
fi

if [ "$SCENARIO" = "ci" ]; then
  if [ "$STATUS" -eq 0 ]; then
    echo "ERROR: CI scenario unexpectedly passed" >&2
    exit 1
  fi
  echo "CI gate result: failed as expected for an unapproved breaking change"
  exit 0
fi

if [ "$SCENARIO" = "wip" ]; then
  if [ "$STATUS" -ne 0 ]; then
    echo "ERROR: WIP scenario failed the command" >&2
    exit 1
  fi
  echo "Expected result: WIP feedback was reported without failing the check"
  exit 0
fi

if [ "$STATUS" -ne 0 ]; then
  echo "ERROR: $SCENARIO scenario failed unexpectedly" >&2
  exit "$STATUS"
fi

echo "Expected result: compatible specifications"
