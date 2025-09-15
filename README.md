```
┏━╸╻┏━╸╻  ┏━╸╺┳╸   ┏━╸┏━┓┏┓╻╺┳╸┏━┓
┣╸ ┃┃╺┓┃  ┣╸  ┃    ┣╸ ┃ ┃┃┗┫ ┃ ┗━┓
╹  ╹┗━┛┗━╸┗━╸ ╹    ╹  ┗━┛╹ ╹ ╹ ┗━┛
```

A collection of ASCII art fonts for Figlet.

CLI

- Product: `swift-figlet-cli`
- Build:
  - `swift build --package-path . -c release`
- Usage:
  - `swift run --package-path . swift-figlet-cli --list-fonts`
  - `swift run --package-path . swift-figlet-cli --random-font` (prints one random font name)
  - `swift run --package-path . swift-figlet-cli --font Standard "Hello World"`
  - `swift run --package-path . swift-figlet-cli --font random "Hello World"` (renders with a random font)
  - `echo hello | swift run --package-path . swift-figlet-cli --font Slant`

Docs

- DocC: published on GitHub Pages at:
  - <https://wrkstrm.github.io/SwiftFigletKit/>
  - If publishing under a fork or different repo name, replace `wrkstrm/SwiftFigletKit` accordingly.

Packaging and environment

- Fonts are bundled as gzip-compressed resources under `Resources/Fonts/*.flf.gz` to reduce size. The library transparently inflates `.flf.gz` at runtime.
- Linux/macOS requirement: `gzip`/`gunzip` must be available on PATH. Verify with:
  - `swift-figlet-cli doctor`
- Editable font sources live under `Sources/SwiftFigletKit/Fonts/{core,duplicates}` and are mirrored into resources via:
  - `npm run figlet:fonts:prepare`

Notes

- Fonts are bundled as SwiftPM resources and discovered via `Bundle.module`.
- The CLI uses Swift Argument Parser and supports long-form flags like
  `--font` and `--list-fonts`.

## Color and gradients

SwiftFigletKit includes lightweight ANSI color helpers (disabled by default in Xcode environments)
and simple gradient rendering across lines.

Single color

```swift
import SwiftFigletKit

if let s = SFKRenderer.render(text: "CLIA", fontName: "random", color: .magenta) {
  print(s)
}
```

Available colors: `.none, .black, .red, .green, .yellow, .blue, .magenta, .cyan, .white`.

- Disable in Xcode sessions (default): `disableColorInXcode: true`
- Force color even in Xcode: pass `forceColor: true` to render overloads.

Line-by-line gradient

```swift
import SwiftFigletKit

if let s = SFKRenderer.renderGradientLines(
  text: "C.L.I.A.",
  fontName: "random",
  // optional custom palette; defaults to [.red,.yellow,.green,.cyan,.blue,.magenta]
  palette: nil,
  randomizePalette: true
) {
  print(s)
}
```

Notes:

- Color APIs return colored strings with ANSI escape codes. Terminals render these; some UIs (like
  Xcode debug console) may not. Use `forceColor` to override suppression when needed.
- Rendering functions remain backward compatible. If you don’t pass a color, output is unchanged.

## Random rendering (fonts + colors)

SwiftFigletKit exposes high‑level APIs to pick random fonts and color strategies with optional
seeding for deterministic output. Fallbacks ensure a plain ANSI‑colored line is returned even when
FIGlet fonts are unavailable.

Types

- `SFKFontStrategy`: `.named("Slant")`, `.random(excluding: ["Standard"])`
- `SFKColorStrategy`:
  - `.single(.cyan)`
  - `.singleRandom(palette: nil)`
  - `.gradient(palette: [.red, .yellow, .green])`
  - `.gradientRandom(palette: nil, shuffle: true)`
  - `.mixedRandom(gradientProbability: 0.5)`
- `SFKRenderOptions`: `prefix`, `suffix`, `newline`, `seed`, `forceColor`, `disableColorInXcode`

APIs

- `SFKRenderer.render(text:font:color:options:) -> String`
- `SFKRenderer.renderRandomBanner(text:color:options:) -> String` // shorthand for `font: .random()`

Examples

Fixed font + single fixed color

```swift
import SwiftFigletKit

let out = SFKRenderer.render(
  text: "Hello",
  font: .named("Slant"),
  color: .single(.cyan),
  options: .init(newline: true)
)
print(out)
```

Random font + single random color

```swift
let out = SFKRenderer.render(
  text: "Hello",
  font: .random(),
  color: .singleRandom(),
  options: .init()
)
```

Random font + gradient palette

```swift
let out = SFKRenderer.render(
  text: "Hello",
  font: .random(),
  color: .gradient(palette: [.red, .yellow, .green]),
  options: .init(newline: true)
)
```

Mixed random (50/50 single vs gradient)

```swift
let out = SFKRenderer.renderRandomBanner(
  text: "Hello",
  color: .mixedRandom(gradientProbability: 0.5)
)
```

Seeded determinism

```swift
let seed: UInt64 = 42
let a = SFKRenderer.renderRandomBanner(text: "Hello", options: .init(seed: seed))
let b = SFKRenderer.renderRandomBanner(text: "Hello", options: .init(seed: seed))
assert(a == b)
```

Excluding fonts when randomizing

```swift
let out = SFKRenderer.render(
  text: "Hello",
  font: .random(excluding: ["Slant", "Standard"]),
  color: .singleRandom()
)
```

Fallback behavior

- If fonts/bundles are unavailable, APIs return a single ANSI‑colored line (no FIGlet art).
- Gradient requests degrade to a single color (first color of the chosen palette).
