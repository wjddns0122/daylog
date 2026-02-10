---
trigger: always_on
---

---

description: "Figma-is-law enforcement: exact spacing, typography, colors, radii, shadows"
globs: ["lib/**/*.dart", "assets/**"]
alwaysApply: true

---

# Design Enforcement (Figma is Law)

## Required inputs

FIGMA URL: https://www.figma.com/design/weg5ALHfqrdqBiimJhkm7q/-%EB%8D%B0%EC%9D%B4%EB%A1%9C%EA%B7%B8?node-id=0-1&m=dev

For any screen/widget/animation implementation, you must have:

- exact HEX colors
- font family + weight + size + letter spacing + line height
- padding/margins
- border radius (often 24px+)
- shadows (blur/spread/offset/opacity)
- component sizes (heights, widths), icon sizes

If any value is missing:

- STOP and ask for the Figma node/frame or exported design tokens.
- Do NOT approximate.

## Daylog vibe constraints

- Minimalist, grayscale (white/grey/black), high-fidelity
- Smooth animations (subtle, not flashy)
- 3D elements: glass-like object in Splash/Hero header
- Marquee text background in Splash + Hero header

## Splash screen required visuals

- White background
- Large "DAYLOG STORY..." marquee text horizontally scrolling (background)
- Center floating 3D glass object (assets: `assets/svgs/logo.svg` or `3d_glass_shape.png`)
- Logic: auth check → route

## Home feed required structure

- `CustomScrollView` + `Slivers`
- `SliverAppBar`: floating/pinned with `assets/images/logo_header.png` left, actions right
- Hero Header: reuse splash aesthetic with parallax/scroll-away
- Sticky toggle bar: list/grid icon toggle (`isGridMode`)
- List mode: chronological cards
- Grid mode: 4 columns, 1px spacing, sorted by `likeCount desc`, images only, square aspect

## Tokenization rule

Centralize all design tokens:

- `AppColors`, `AppTextStyles`, `AppRadii`, `AppShadows`, `AppSpacing`
  No hard-coded magic numbers in widgets unless explicitly specified by Figma.
