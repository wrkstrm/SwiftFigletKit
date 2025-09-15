#!/usr/bin/env bash
set -euo pipefail

# Deterministically compress per-font .flf files into .flf.gz for packaging.
# - Uses gzip -n to strip timestamps/original filename, for reproducible bytes.
# - Mirrors directory layout under an output root.

SRC_DIR="${1:-Sources/SwiftFigletKit/Resources/Fonts}"
OUT_DIR="${2:-Sources/SwiftFigletKit/ResourcesGZ/Fonts}"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Source fonts directory not found: $SRC_DIR" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

shopt -s nullglob
count=0
for f in "$SRC_DIR"/*.flf; do
  base=$(basename "$f")
  out="$OUT_DIR/$base.gz"
  mkdir -p "$(dirname "$out")"
  # gzip -n for reproducible output; -c to stdout, > to file
  gzip -n -c "$f" > "$out"
  ((count++))
done

echo "Compressed $count fonts to $OUT_DIR"

