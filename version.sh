#!/usr/bin/env bash
set -euo pipefail

BUMP="${1:-patch}"  # patch | minor | major

INIT_LUA="WindowStow.spoon/init.lua"
DOCS_JSON="docs/docs.json"
ZIP_PATH="Spoons/WindowStow.spoon.zip"

# --- Read current version ---
CURRENT=$(grep -oE 'obj\.version = "[^"]+"' "$INIT_LUA" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')
if [[ -z "$CURRENT" ]]; then
  echo "Error: could not find obj.version in $INIT_LUA" >&2
  exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
PATCH=${PATCH:-0}

# --- Bump ---
case "$BUMP" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
  *)
    echo "Usage: $0 [patch|minor|major]" >&2
    exit 1
    ;;
esac

NEW="${MAJOR}.${MINOR}.${PATCH}"

echo "Bumping $CURRENT → $NEW"

# --- Update init.lua ---
sed -i '' "s/obj\\.version = \"${CURRENT}\"/obj.version = \"${NEW}\"/" "$INIT_LUA"

# --- Update docs/docs.json ---
sed -i '' "s/\"version\": \"${CURRENT}\"/\"version\": \"${NEW}\"/" "$DOCS_JSON"

# --- Regenerate zip ---
rm -f "$ZIP_PATH"
zip -r "$ZIP_PATH" WindowStow.spoon/ > /dev/null
echo "Regenerated $ZIP_PATH"

# --- Commit & tag ---
git add "$INIT_LUA" "$DOCS_JSON" "$ZIP_PATH"
git commit -m "Release v${NEW}"
git tag "v${NEW}"

echo "Done: v${NEW} committed and tagged"
echo "Push with: git push && git push --tags"
