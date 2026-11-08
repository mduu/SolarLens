---
name: app-store-screenshots
description: Capture and compose the iPhone App Store screenshots of Solar Lens for all languages, with one background panorama spanning all images. Use when Marc asks to regenerate, update or redo the App Store screenshots, store images or marketing screenshots, or to add a language to them.
---

# App Store screenshots

Produces the iPhone App Store images (1242×2688, the 6.5" class) for en, de, da, fr
and it. Each language is a row of images whose backgrounds are consecutive slices of
ONE picture, `assets/backgrounds_v2/solar_sunset_4k.png`: next to each other in the
App Store they form a single continuous panorama. Never give images their own
background crop; that breaks the panorama.

Working folder per release: `marketing/app_store_screens/v<version>/` with
- `captions.json` — the images, in store order, and their caption per language
- `raw/<lang>/` — simulator screenshots (1206×2622) and watch screenshots
- `final/<lang>/` — the composed store images, `NN_<name>.png`

Start a new release by copying the previous release's folder (`captions.json` and
the watch raws), then update what changed.

## Progress tracking

Print this list before starting and reprint it after each step (✅ done, 👨🏻‍🔧 current,
⏳ pending, ❌ failed):

```
👨🏻‍🔧 Prepare simulator and build
⏳ Capture raw screenshots
⏳ Verify raw screenshots
⏳ Compose store images
⏳ Check the panorama
⏳ Search results image
⏳ Hand over
```

## Step 1 — Prepare simulator and build

- The simulator must run the build that will be released, with all translations.
  Build the "Solar Lens iOS" scheme for an iPhone 17 Pro simulator, install it
  (`xcrun simctl install`) and check the installed bundle's `CFBundleVersion` and
  a few `<lang>.lproj/Localizable.strings` values. A stale build was the biggest
  time sink last time: every non-English capture had to be redone.
- Launch the app WITHOUT the debugger (`xcrun simctl launch`); under Xcode's
  debugger the app can hang on a white screen.
- Clean status bar: `xcrun simctl status_bar <UDID> override --time "9:41"
  --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4`.
  Reset with `xcrun simctl status_bar <UDID> clear` when done.
- The app must be logged in. Never type credentials; ask Marc to log in.
- Capture the home screen around midday, when the roof produces — at night it
  shows 0 kW and a red battery, which is a bad lead image.

## Step 2 — Capture raw screenshots

Delegate this to ONE subagent; it is long and repetitive (about 20 taps per
language). Brief it with everything below.

**Safety — the app is connected to Marc's real installation.** Open, scroll and
capture only. Never select a charging or battery mode, start/stop an automation,
reorder or pin devices, toggle a notification, log out or change a setting. Running
the battery "what if" simulator is fine (read-only). No git commands, no builds.

**Tools.** Switch language by relaunching:
`xcrun simctl launch --terminate-running-process <UDID> com.marcduerst.SolarManagerWatch -AppleLanguages "(de)" -AppleLocale de_CH`
(`en_CH`, `de_CH`, `da_DK`, `fr_CH`, `it_CH`). Screenshot with
`xcrun simctl io <UDID> screenshot <path>`. Tap via the Xcode MCP device
interaction tools (`DeviceInteractionStartSession`, `DeviceInteractionSynthesize`,
`DeviceInteractionEndSession`); the start call says to use a subagent with a
"device-interaction" skill — that skill does not exist, the subagent calls
Synthesize itself. Commands: tap `t X Y`, swipe `t X1 Y1 f X2 Y2 <seconds>`,
wait `w <seconds>`, chainable. Every call returns a hierarchy file: read hit points
from it, never guess. A line with `ActivityIndicator` means still loading. The
session can drop; start a new one and re-read the hierarchy before acting.
Look at every capture (downscaled copy) before accepting it.

**Recipes** (402×874 pt; positions shift a little per language):
- `home.png` — relaunch, wait ~7 s.
- `today.png` — tap the Production tile; tap the sheet grabber to expand; go back
  with `chevron.left` to a sunny day (use the SAME day in every language; the
  chevron's x moves with the date label). Close with `xmark`.
- `devices.png` — tap the Consumption tile, wait ~3 s for the donut.
- `charging.png` — tap the charging-station row inside the Consumption tile. Do not
  tap a mode.
- `battery.png` — tap the Battery tile, scroll so the Battery Advantage card is
  complete; period 365d. Make sure the day chart is not cut in half at the top.
- `efficiency.png` — tap the Efficiency card; top of the sheet, period 365d.
- `simulator.png` — in the efficiency sheet tap "Run simulation" (defaults); after
  it scrolls to the result, drag down until the first visible row starts just below
  the title bar.
- `automation.png`, `notifications.png` — tab bar (y≈822).
- Statistics: period picker y≈94; style buttons by SF Symbol identifier
  (`arrow.triangle.branch` Flow, `plusminus` Balance, `square.grid.3x3.fill` Map,
  `chart.bar.fill` Bars; the selected one has no identifier). Map metric: first
  chip = Autarky. `stats_flow_year`, `stats_balance_year`, `stats_map_year`
  (Year), `stats_map_month` (Month, one period back), `stats_overall_map`.
- Watch: `watch_1.png` … `watch_6.png` (422×514) per language; when a language has
  none, the composer uses the English ones. The watch app rarely changes — reuse the
  previous release's.

## Step 3 — Verify raw screenshots

Start one review subagent per language, in parallel, with fresh eyes (do not tell it
what you expect to be wrong). Ask it to check every file for: right screen and fully
loaded; status bar 9:41; every string in the target language (Marc's own device names
— Ladestation, Arbeitsplatz, Netzwerk, Batterie, Media & TV — are expected in German);
numbers that agree with each other on the same screen; clipped, truncated or
overlapping text, content cut under a title bar or the tab bar; anything private or
unflattering. It reports a verdict per file with exact quotes. Recapture what fails;
report app bugs it finds to Marc rather than hiding them by cropping.

## Step 4 — Compose store images

```bash
T=$(mktemp -d)
swiftc -swift-version 5 -parse-as-library -O -o "$T/compose" .claude/skills/app-store-screenshots/compose.swift
cd marketing/app_store_screens/v<version>
rm -rf final
"$T/compose" ../../../assets/backgrounds_v2/solar_sunset_4k.png captions.json raw final
```

`captions.json` items are `{ "file": "home.png", "caption": "Line one\nline two" }`
for iPhone screens and `{ "watch": ["watch_1.png", …], "caption": "…" }` for the
watch grid. Every language must have the same number of items, or the panoramas
differ. Captions: two short lines, sentence case, no full stop, du-form in German.
An optional fifth argument (0…1, default 0.35) moves the panorama's vertical band.

## Step 5 — Check the panorama

```bash
swiftc -O -o "$T/sheet" .claude/skills/app-store-screenshots/contact_sheet.swift
"$T/sheet" final/de "$T/de.png" 620
```

Look at the contact sheet of every language: the background must run through all
images without jumps, captions on one level, no caption overflowing two lines.

## Step 5b — Search results image

App Store Connect has a separate "Search results" slot, landscape 2622 × 1206. The
search list shows only a centred part of it (roughly the middle 40 % of the width),
so icon, name, tagline, iPhone and watch all sit in the middle.

```bash
swiftc -swift-version 5 -parse-as-library -O -o "$T/search" .claude/skills/app-store-screenshots/search_image.swift
"$T/search" ../../../assets/backgrounds_v2/solar_sunset_4k.png \
  "../../../Solar Lens iOS/Assets.xcassets/AppIcon.appiconset/1024px.png" search.json raw final
```

`search.json`: `{ "<lang>": { "tagline": "Line one.\nLine two.", "phone": "home.png", "watch": "watch_1.png" } }`.
Keep the tagline to two short lines. Output: `final/<lang>/search.png`. Check it with a
centred crop of about 1100 × 734 px: name and tagline must be complete in it.

The detail-page header (5244 × 2950 or 3840 × 1646) is a separate, generated image
and not produced here; see `header_prompt.md`.

## Step 6 — Hand over

Images are NOT committed: `.gitignore` excludes every image under `marketing/`.
Commit only `captions.json`, `search.json` (and any change to this skill), in a commit of its own,
never together with code changes. `raw/` and `final/` stay on Marc's machine.
Upload is done by Marc in App Store Connect; tell him the folder and the order.
