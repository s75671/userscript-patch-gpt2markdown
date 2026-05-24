# userscript-patch-workflow

This repository downloads an upstream userscript and applies a narrow local patch.

The GitHub Actions workflow is intentionally generic: it downloads a source file, runs a configured patch script, verifies the output, and uploads the patched file as an artifact. The userscript-specific patch rules live in `scripts/patch-export-chat-md.sh`.

## Current patch scope

For the upstream `Export ChatGPT/Gemini/Grok conversations as Markdown` userscript, the patch script only does the following:

1. Removes unused `@grant` permissions.
2. Removes `@downloadURL` and `@updateURL` metadata lines.
3. Removes the `trustedTypes.createPolicy("default", ...)` block.

No other fixes are applied.

## Run locally

```sh
./scripts/patch-export-chat-md.sh
```

By default it downloads from:

```text
https://update.greasyfork.org/scripts/543471/Export%20ChatGPTGeminiGrok%20conversations%20as%20Markdown.user.js
```

The patched file is written to:

```text
dist/Export_ChatGPT_Gemini_Grok_conversations_as_Markdown.patched.user.js
```

You can override paths and URL:

```sh
SOURCE_URL="https://example.com/script.user.js" \
OUTPUT_FILE="dist/script.patched.user.js" \
./scripts/patch-export-chat-md.sh
```

## GitHub Actions

The workflow can be run manually from the Actions tab. It supports these inputs:

- `source_url`: URL to download.
- `output_file`: output path for the patched file.
- `patch_script`: shell script that applies the patch.
- `commit_changes`: set to `true` to commit the generated patched file back to the repository.

By default, the workflow only uploads the patched userscript as an artifact and does not commit changes.
