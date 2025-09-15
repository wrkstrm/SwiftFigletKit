#!/usr/bin/env bash
set -euo pipefail

# Prepare package resources from top-level Fonts/ directory.
# - Copies Sources/SwiftFigletKit/Fonts/core/*.flf into Sources/SwiftFigletKit/Resources/Fonts
# - Optionally creates gz variants into Sources/SwiftFigletKit/ResourcesGZ/Fonts

PKG_SRC_ROOT="code/mono/apple/spm/universal/SwiftFigletKit"
PKG_ROOT="code/mono/apple/spm/universal/SwiftFigletKit/Sources/SwiftFigletKit"
SRC_TOP="${1:-$PKG_SRC_ROOT/Fonts/core}"
DO_GZIP="${DO_GZIP:-1}"

if [[ ! -d "$SRC_TOP" ]]; then
  echo "Top-level fonts not found at $SRC_TOP; run scripts/snapshot-fonts-to-top-level.sh first" >&2
  exit 1
fi

DEST_RESOURCES_FONTS="$PKG_ROOT/Resources/Fonts"
mkdir -p "$DEST_RESOURCES_FONTS"

# Clean destination to avoid mixing plain/gz
find "$DEST_RESOURCES_FONTS" -type f -name '*' -print -delete >/dev/null 2>&1 || true

if [[ "$DO_GZIP" == "1" ]]; then
  # Deterministically compress each .flf into Resources/Fonts as .flf.gz
  shopt -s nullglob
  count=0
  for f in "$SRC_TOP"/*.flf; do
    base=$(basename "$f")
    gzip -n -c "$f" > "$DEST_RESOURCES_FONTS/$base.gz"
    ((count++))
  done
  echo "Compressed $count fonts to $DEST_RESOURCES_FONTS"
else
  # Fallback: copy plain .flf if gzip disabled
  rsync -a --delete "$SRC_TOP/" "$DEST_RESOURCES_FONTS/"
fi

echo "Prepared package resources from $SRC_TOP -> $DEST_RESOURCES_FONTS"
