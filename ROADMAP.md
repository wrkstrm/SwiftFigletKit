# SwiftFigletKit Roadmap

This roadmap tracks SwiftFigletKit work: fonts lifecycle, packaging, docs, and CLI tooling.

## Done (2025‑09)

- Fixed SFKFigletFile parsing and line‑ending normalization; added UTF‑8 with ISO‑Latin‑1 fallback for legacy fonts; all tests pass.
- Added DocC catalog with a generated Fonts Gallery; gallery shows per‑font ASCII art and an optional “Reported name” extracted from comment lines.
- Generator tool `swift-figlet-doc-gen` outputs the gallery, alias groups, and delete plans; npm scripts wire generation and build.
- Hash‑based duplicate detection and curation plan created; moved “complicated” duplicate names (spaces/uppercase) to `Sources/SwiftFigletKit/Fonts/duplicates` and kept simple canonical files in `Sources/SwiftFigletKit/Fonts/core`.
- Added `swift-figlet-dedupe` tool to produce deterministic move plans (and apply, if desired).
- Introduced gzip‑per‑font packaging; switched the package to bundle `ResourcesGZ/Fonts` (.flf.gz). Runtime lazily inflates on demand; CLI list shows clean names.
- Scripts:
  - `figlet:fonts:snapshot` → snapshot old Resources/Fonts into `Sources/SwiftFigletKit/Fonts/`
  - `figlet:fonts:prepare` → mirror Fonts/core into Resources and build deterministic .flf.gz
  - `figlet:fonts:gzip` → deterministic gzip per font
- Full font sweep on gz‑only bundle: 365 fonts listed, 0 broken renders.

## Next

- Cross‑platform inflate: replace external `gunzip -c` fallback with a pure‑Swift gzip decoder for Linux/CI portability.
- CI automation:
  - Run `figlet:fonts:prepare` before packaging/docs to ensure `ResourcesGZ/Fonts` is refreshed and deterministic.
  - Run `docs:figlet:build+gallery` in release docs pipeline.
- Naming discipline:
  - Optional normalization to enforce canonical simple filenames (lowercase, no spaces) in `Fonts/core/` with a mapping for display names in docs.
- Cleanup legacy paths:
  - Remove (or explicitly exclude) unused `Resources/Fonts/` from the package tree.
- Flags and diagnostics:
  - Add a `--strict-utf8` render mode to opt‑out of Latin‑1 fallback.
  - Add verbose logging option for font load failures (path, header line) outside DEBUG builds.
- Docs polish:
  - Add “Design & Packaging” DocC article explaining gz packaging, hashing, and lazy load behavior.
  - Publish size/save metrics (tar.gz and per‑font gz) and add a badge in README.

## Commands (quick reference)

- Generate gallery + build docs:
  - `npm run docs:figlet:build+gallery`
- Dedupe (dry‑run / apply):
  - `npm run docs:figlet:dedupe:dry-run`
  - `npm run docs:figlet:dedupe:apply`
- Prepare fonts for packaging (mirrors Fonts/core → Resources, builds gz):
  - `npm run figlet:fonts:prepare`
- Snapshot legacy Resources to package Fonts/ (one‑time migration aid):
  - `npm run figlet:fonts:snapshot`

## Paths

- Package fonts (editable): `Sources/SwiftFigletKit/Fonts/{core,duplicates}`
- Bundled resources (shipping): `Sources/SwiftFigletKit/ResourcesGZ/Fonts/*.flf.gz`
- DocC catalog: `Sources/SwiftFigletKit/SwiftFigletKit.docc/`

