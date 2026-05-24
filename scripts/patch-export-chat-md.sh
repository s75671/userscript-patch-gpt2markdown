#!/usr/bin/env sh
set -eu

SOURCE_URL="${SOURCE_URL:-https://update.greasyfork.org/scripts/543471/Export%20ChatGPTGeminiGrok%20conversations%20as%20Markdown.user.js}"
OUTPUT_FILE="${OUTPUT_FILE:-dist/Export_ChatGPT_Gemini_Grok_conversations_as_Markdown.patched.user.js}"
WORK_DIR="${WORK_DIR:-.work}"
SOURCE_FILE="$WORK_DIR/upstream.user.js"
PATCHED_FILE="$WORK_DIR/patched.user.js"

mkdir -p "$WORK_DIR" "$(dirname "$OUTPUT_FILE")"

curl -fsSL "$SOURCE_URL" -o "$SOURCE_FILE"
cp "$SOURCE_FILE" "$PATCHED_FILE"

# Patch 1: remove unused userscript permissions.
# Keep only permissions actually used by the current script.
# Do not remove functions or make unrelated code changes.
sed -i.bak \
  -e '/^[[:space:]]*\/\/ @grant[[:space:]]\+GM_registerMenuCommand[[:space:]]*$/d' \
  -e '/^[[:space:]]*\/\/ @grant[[:space:]]\+GM_openInTab[[:space:]]*$/d' \
  -e '/^[[:space:]]*\/\/ @grant[[:space:]]\+GM\.openInTab[[:space:]]*$/d' \
  -e '/^[[:space:]]*\/\/ @grant[[:space:]]\+GM_setValue[[:space:]]*$/d' \
  -e '/^[[:space:]]*\/\/ @grant[[:space:]]\+GM_getValue[[:space:]]*$/d' \
  -e '/^[[:space:]]*\/\/ @grant[[:space:]]\+GM_xmlhttpRequest[[:space:]]*$/d' \
  "$PATCHED_FILE"
rm -f "$PATCHED_FILE.bak"

# Patch 2: remove automatic-update metadata.
sed -i.bak \
  -e '/^[[:space:]]*\/\/ @downloadURL[[:space:]]/d' \
  -e '/^[[:space:]]*\/\/ @updateURL[[:space:]]/d' \
  "$PATCHED_FILE"
rm -f "$PATCHED_FILE.bak"

# Patch 3: remove the default Trusted Types policy block only.
# This matches the compact IIFE block used by the upstream script.
python3 - "$PATCHED_FILE" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

pattern = re.compile(
    r"\n\s*\(\(\)\s*=>\s*\{\s*"
    r"if\s*\(\s*typeof\s+trustedTypes\s*!==\s*[\"']undefined[\"']\s*&&\s*trustedTypes\.defaultPolicy\s*===\s*null\s*\)\s*\{\s*"
    r"let\s+s\s*=\s*\(\s*s2\s*\)\s*=>\s*s2\s*;\s*"
    r"trustedTypes\.createPolicy\(\s*[\"']default[\"']\s*,\s*\{\s*createHTML\s*:\s*s\s*,\s*createScriptURL\s*:\s*s\s*,\s*createScript\s*:\s*s\s*\}\s*\)\s*;\s*"
    r"\}\s*"
    r"\}\)\(\)\s*;\s*\n",
    re.DOTALL,
)

new_text, count = pattern.subn("\n", text)
if count != 1:
    raise SystemExit(f"expected to remove exactly one trustedTypes default policy block, removed {count}")

path.write_text(new_text, encoding="utf-8")
PY

cp "$PATCHED_FILE" "$OUTPUT_FILE"

# Narrow verification: fail if any targeted metadata or Trusted Types default policy remains.
if grep -Eq '^[[:space:]]*// @grant[[:space:]]+(GM_registerMenuCommand|GM_openInTab|GM\.openInTab|GM_setValue|GM_getValue|GM_xmlhttpRequest)[[:space:]]*$' "$OUTPUT_FILE"; then
  echo "targeted unused @grant line still exists" >&2
  exit 1
fi

if grep -Eq '^[[:space:]]*// @(downloadURL|updateURL)[[:space:]]' "$OUTPUT_FILE"; then
  echo "automatic update metadata still exists" >&2
  exit 1
fi

if grep -Fq 'trustedTypes.createPolicy("default"' "$OUTPUT_FILE" || grep -Fq "trustedTypes.createPolicy('default'" "$OUTPUT_FILE"; then
  echo "Trusted Types default policy still exists" >&2
  exit 1
fi

printf '%s\n' "patched file written to $OUTPUT_FILE"
