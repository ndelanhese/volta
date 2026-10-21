# Application icon

`Resources/AppIcon.png` is the original artwork, generated with the built-in image generation tool.
`Resources/AppIcon.icns` packages the icon for Finder, Spotlight, and application launchers.
To regenerate every standard and Retina representation after changing the artwork, run:

```bash
./scripts/build-icon.sh
```

The build copies the ICNS into the app resources and references it through `CFBundleIconFile`.
The menu bar keeps its monochrome template symbol so it remains readable in light and dark modes.

## Generation prompt

Create a finished macOS application icon for Volta, a free local utility that returns windows to their places across multiple monitors. Single icon, square 1024 x 1024 canvas, transparent exterior around a carefully proportioned macOS rounded-square tile (about 84 percent of canvas width). Rich cobalt blue to deep azure tile with subtle dimensional ceramic/glass finish, controlled lighting and a thin luminous edge; premium, calm, crisp, no garish glow. Center an original arrangement of exactly three rounded rectangular window panels: two landscape windows stacked on the left, one tall portrait window on the right, all aligned with clear generous spacing. Panels are luminous icy white frosted glass with a delicate pale blue tint and subtle depth; strong readable silhouettes at 32 pixels. A restrained small return motion detail may be integrated only if it remains exceptionally clean. Front view, no perspective tilt, no lettering, no typography, no watermarks, no mockup, no border frame around canvas, no extra objects. The icon should feel polished and friendly alongside native macOS apps. Output actual transparent alpha outside the rounded square; do not draw a checkerboard.

Transparency was requested from the image generation tool and preserved during native ICNS packaging.
