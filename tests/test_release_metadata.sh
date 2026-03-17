#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODULE_JSON="$ROOT_DIR/src/module.json"
RELEASE_JSON="$ROOT_DIR/release.json"
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/release.yml"

for f in "$MODULE_JSON" "$RELEASE_JSON" "$WORKFLOW_FILE"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: Missing required file: $f" >&2
    exit 1
  fi
done

module_version="$(python3 -c "import json;print(json.load(open('$MODULE_JSON'))['version'])")"
release_version="$(python3 -c "import json;print(json.load(open('$RELEASE_JSON'))['version'])")"
release_url="$(python3 -c "import json;print(json.load(open('$RELEASE_JSON'))['download_url'])")"

if [ "$module_version" != "$release_version" ]; then
  echo "FAIL: Version mismatch: src/module.json=$module_version release.json=$release_version" >&2
  exit 1
fi

expected_url="https://github.com/handcraftedcc/move-everything-chordflow/releases/download/v${release_version}/chord-flow-module.tar.gz"
if [ "$release_url" != "$expected_url" ]; then
  echo "FAIL: release.json download_url mismatch: got=$release_url expected=$expected_url" >&2
  exit 1
fi

if ! rg -q "tags:" "$WORKFLOW_FILE"; then
  echo "FAIL: release workflow must trigger on tags" >&2
  exit 1
fi

if ! rg -q "\"v\\*\"" "$WORKFLOW_FILE"; then
  echo "FAIL: release workflow must include v* tag filter" >&2
  exit 1
fi

if ! rg -q "softprops/action-gh-release@" "$WORKFLOW_FILE"; then
  echo "FAIL: release workflow missing action-gh-release step" >&2
  exit 1
fi

if ! rg -q "dist/chord-flow-module.tar.gz" "$WORKFLOW_FILE"; then
  echo "FAIL: release workflow missing chord-flow artifact path" >&2
  exit 1
fi

echo "PASS: release metadata and workflow checks"
