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
