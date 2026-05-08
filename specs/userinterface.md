# Solar Lens – User Interface Guidelines

## Design Philosophy

Solar Lens is designed for **daily use by homeowners**, not engineers. The interface should feel approachable and calm — providing clarity about your energy system without requiring technical knowledge. Every screen should answer a simple question ("Am I producing enough?", "Is my battery full?", "How efficient was my day?") at a glance.

### Core Principles

1. **Glanceable** — Key information is visible without scrolling or tapping. Widgets, complications, and home screens prioritize the most important number or status.
2. **Calm, not alarming** — Use warm colors and smooth animations. Avoid red/error styling for normal operating states. Solar energy is positive — the UI should reflect that.
3. **Consistent across platforms** — Watch, phone, and TV share the same visual language and component patterns, adapted to each screen size.
4. **Platform-native** — Follow Apple's Human Interface Guidelines. Use SF Symbols, system fonts, and standard navigation patterns. No custom chrome that fights the OS.

## Color Palette

### Semantic Colors

| Color | Usage | SwiftUI |
|-------|-------|---------|
| **Yellow** | Solar production, accent, primary brand | `.yellow` (AccentColor) |
| **Teal** | Consumption | `.teal` |
| **Green** | Battery level, positive states | `.green` |
| **Purple** | Interactive controls (battery mode buttons) | `.purple` |
| **Orange** | Warnings, grid import | `.orange` |
| **Red** | Errors, high grid import | `.red` |
| **Gray** | Neutral, inactive, timestamps | `.gray` |

### Color Rules

- Use **semantic colors consistently** across all platforms — yellow always means solar, teal always means consumption.
- Colors can be lightened (`.lighten()`) or darkened (`.darken()`) for variants, but the base hue should stay recognizable.
- Custom hex colors via `Color(hex6:)` or `Color(rgbString:)` extensions when needed.

## Typography

Solar Lens uses **system fonts exclusively** — no custom typefaces.

### Text Hierarchy

| Level | Style | Usage |
|-------|-------|-------|
| Primary header | `.title2` | Screen titles, large values |
| Secondary header | `.title3` | Section titles with icons |
| Emphasis | `.headline` | Highlighted values, section labels |
| Body | `.body` | Standard content |
| Secondary | `.subheadline` | Supporting text |
| Caption | `.caption` / `.caption2` | Timestamps, labels, small annotations |

### Font Weight Guidelines

- **Bold** — Percentages, key metrics
- **Semibold** — Selected states, emphasized headers
- **Medium** — Secondary labels (sun times, chart annotations)
- **Regular** — Body text, descriptions

## Components

### Cards (`.cardStyle()` modifier)

The primary container for grouping related information.

- **Material:** `.ultraThickMaterial` (glass morphism, adapts to dark/light)
- **Corner radius:** 20pt
- **Padding:** 14pt horizontal, 16pt vertical
- **Width:** Full available width

Use cards to group a feature's data (e.g., battery card, solar card, consumption card).

#### AI variant (active automations)

Reserved for cards that surface a running automation or other "AI-driven"
state. Built on the standard card geometry (corner radius 20pt, full width)
with a brighter material fill and two stacked overlays:

- **Fill:** `.regularMaterial` (slightly more present than `.ultraThickMaterial`).
- **Border:** `AICardBorder` — a `RoundedRectangle.stroke` driven by an
  `AngularGradient` of the Solar Lens brand colours (**yellow → white →
  orange**) animated via `TimelineView`. Stroke width 5pt.
- **Glow:** `AICardGlow` — a blurred halo behind the card (`.padding(-6)`)
  using the same gradient at lower opacity.
- **Accents:** `sparkles` SF Symbol with the gradient, and the running-pill
  pattern from "Symbol Effects" above (pulsing icon + "Running" label).

Gradient stops live as constants in `AutomationBrand` (shared module) — never
redefine them inline in a card. The same constants are used by the iOS Live
Activity Lock Screen card so the brand reads identically inside and outside
the app.

Use this variant only for genuinely active states. Idle automation cards stay
on the standard `.cardStyle()` so the AI treatment retains meaning.

### MiniDonut

Circular progress indicator for percentages (battery level, efficiency).

- Angular gradient from 70% to 100% opacity
- Center text shows percentage value
- Configurable line width (default 4pt) and colors

### UpdateTimeStampView

Data freshness indicator shown on dashboards.

- Relative time display ("Updated 5m 30s")
- Pulsing refresh icon when loading
- Tap-to-refresh with `.easeInOut(duration: 0.2)` animation
- Stale data warning when >60s old

### IntPicker

Plus/minus stepper for numeric values (e.g., charging power).

- Bordered circular buttons
- Animated value changes
- Configurable tint color

## Icons

**SF Symbols only** — no custom icon assets.

### Rendering Modes

- **Multicolor** — Symbols with inherent color meaning (sunrise, sunset, battery states)
- **Palette** — Two-color combinations (e.g., green + primary for positive states)
- **Standard** — Single color, inherits from context

### Symbol Effects (Animation)

| Effect | Usage |
|--------|-------|
| `.pulse.wholeSymbol` | Active states (battery charging) |
| `.breathe.pulse.wholeSymbol` | Continuous activity (charging station active) |
| `.rotate.byLayer` | Refresh/loading |
| `.pulse` (repeating) | "Something is running" indicator — running-card status pill, tab badge (e.g. rocket icon while an automation is active) |

Use symbol effects sparingly — they should draw attention to active processes, not create visual noise.

### Tab badges with icons

Prefer an SF Symbol over a numeric badge when the count is degenerate (always
0 or 1, e.g. the Automation tab — at most one automation runs at a time).
Pass `Text(Image(systemName: "rocket.fill"))` to `.badge(_:)`; pass `nil` to
hide it entirely. A meaningless `1` reads as a notification count and trains
the user to dismiss it.

## Animation

### Timing

| Context | Duration | Easing |
|---------|----------|--------|
| User interaction (tap, toggle) | 0.2s | `.easeInOut` |
| Background transitions (solar intensity) | 2.0s | `.easeInOut` |
| Symbol effects | Continuous | System default |

### Rules

- **Disable animation on data refreshes** — Use `.animation(nil, value:)` to prevent jarring layout shifts when data updates.
- **Animate user-initiated changes** — Wrap state changes from user actions in `withAnimation`.
- **God rays** — Solar production intensity drives a subtle ray animation on iOS backgrounds. Keep opacity low (0.45 dark, 0.90 light) so it doesn't distract.

## Dark Mode

Solar Lens fully supports dark mode on all platforms.

### Background Adaptation

- **Light mode:** Cool mesh gradient (blue-gray hues, brightness 0.82–0.94)
- **Dark mode:** Dark mesh gradient (same hues, brightness 0.08–0.14)
- **Legacy fallback (< iOS 18):** Linear gradient (#CDD4DE → #E8EBF0 light, #0A1628 → #0D0D0D dark)

### Rules

- Use `.ultraThickMaterial` for cards — it adapts automatically.
- Detect scheme with `@Environment(\.colorScheme)` only when explicit adjustments are needed (e.g., overlay opacity, god ray intensity).
- Never hardcode white or black backgrounds — always use adaptive materials or scheme-aware colors.

## Platform-Specific Guidelines

### watchOS

- Compact layouts — Grid-based energy flow (3x3)
- Shorter content — no scrolling for primary data
- Sheet presentations for mode selection dialogs
- Conditional minimum heights for small vs. large watch faces (`minHeightSmallWatch` / `minHeightLargeWatch`)
- Simpler backgrounds — solid or linear gradient (no god rays)

### iOS

- Full-screen scrollable layouts
- Portrait/landscape responsive via `isPortrait` checks and size classes
- Rich backgrounds with mesh gradients and god ray effects
- Half-sheet modals (`.presentationDetents([.medium])`) for secondary actions
- Tab-based primary navigation

### tvOS (BigScreen)

- Large spacing — 30pt padding and corner radius (`BorderBox`)
- Theme system (`ColorTheme` protocol) for custom appearance
- No symbol effects (limited tvOS support)
- Simpler component variants (`small: true`)
- Focus-based navigation (Apple TV remote)

## Spacing & Layout Tokens

| Token | Value | Usage |
|-------|-------|-------|
| Spacing XS | 4pt | Icon gaps, tight padding |
| Spacing S | 8pt | FlowLayout default, small gaps |
| Spacing M | 14–16pt | Card padding, standard spacing |
| Spacing L | 20pt | Card corner radius, section gaps |
| Spacing XL | 30pt | tvOS containers |

### Corner Radius Scale

| Size | Value | Usage |
|------|-------|-------|
| Small | 5pt | Forecast items, compact cards |
| Medium | 8–12pt | Icon backgrounds, selected overlays |
| Large | 20pt | Primary cards |
| XL | 30pt | tvOS containers |

## Opacity Scale

| Level | Value | Usage |
|-------|-------|-------|
| Subtle | 0.08 | Unselected backgrounds |
| Soft | 0.12–0.15 | Selected state (dark), medium overlays |
| Visible | 0.20 | Refreshable indicator background |
| Background image | 0.20–0.30 | Photo overlay (scheme-dependent) |
| God rays | 0.45–0.90 | Solar effect (dark–light) |

## Responsive Layout

Use environment values for adaptive layouts:

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass
@Environment(\.verticalSizeClass) var verticalSizeClass
```

- **HVStack** — Switches between VStack/HStack based on orientation
- **FlowLayout** — Word-wrap layout for tag-like arrangements
- Use `#if os(watchOS)` compilation conditionals for platform-specific sizing, not runtime checks
