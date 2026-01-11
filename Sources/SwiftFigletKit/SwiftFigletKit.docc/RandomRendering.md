# Random Rendering

Learn how to render banners with random fonts and colors using `SwiftFigletKit`.

## Overview

The high‑level APIs in `SFKRenderer` combine font selection and color strategies into a single
call. You can:

- Choose fonts by name or randomly (with exclusions) using `SFKFontStrategy`.
- Colorize with single or gradient styles, or mix randomly using `SFKColorStrategy`.
- Provide a seed for deterministic output via `SFKRenderOptions`.

When FIGlet fonts aren’t available, the APIs return a plain ANSI‑colored line so your app can still
show a banner without failing.

## Choose A Strategy

- `SFKFontStrategy`: `SFKFontStrategy/named(_:)` or `SFKFontStrategy/random(excluding:)`
- `SFKColorStrategy`: `SFKColorStrategy/single(_:)`,
  `SFKColorStrategy/singleRandom(palette:)`, `SFKColorStrategy/gradient(palette:)`,
  `SFKColorStrategy/gradientRandom(palette:shuffle:)`,
  `SFKColorStrategy/mixedRandom(gradientProbability:singlePalette:gradientPalette:)`
- `SFKRenderOptions`: `prefix`, `suffix`, `newline`, `seed`, `forceColor`, `disableColorInXcode`

## Render with A Random Font

```swift
import SwiftFigletKit

let banner = SFKRenderer.renderRandomBanner(text: "Hello")
print(banner)
```

## Fixed Font, Single Color

```swift
let out = SFKRenderer.render(
  text: "Hello",
  font: .named("Slant"),
  color: .single(.cyan),
  options: .init(newline: true)
)
```

## Mixed Random Colors with Seed

```swift
let seed: UInt64 = 42
let out = SFKRenderer.renderRandomBanner(
  text: "Hello",
  color: .mixedRandom(gradientProbability: 0.5),
  options: .init(seed: seed)
)
```

## Fallback Behavior

If FIGlet fonts are unavailable, the functions return a single ANSI‑colored line. Gradient
strategies degrade to a single color (first entry in the chosen palette).
