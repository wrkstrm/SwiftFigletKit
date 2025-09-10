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
