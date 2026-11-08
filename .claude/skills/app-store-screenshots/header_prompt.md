# Prompt for the App Store header (detail page)

The header is generated with an image model (the current one came from ChatGPT),
not composed by the scripts in this skill. Supported sizes in App Store Connect:
5244 × 2950 or 3840 × 1646. The iPhone shows it in a slightly narrower format than
16:9 and puts the status bar and the back/share buttons on top of it, so the
outer edges and the top corners are lost.

Attach the current header (`marketing/app_store_headers/SolarLensHeader_<LANG>_5244x2950.png`)
and use, per language:

```
Recreate the attached App Store header with the same scene, lighting and style,
at exactly 5244 × 2950 pixels, with these layout changes:

- Keep all text and the app icon well inside the image: at least 12 % of the width
  away from the left and right edges, and at least 14 % of the height away from the
  top edge. Nothing important in the top-left or top-right corner (system buttons
  sit there).
- Place the app icon and the name "SOLAR LENS" side by side, then below it the
  tagline "<TAGLINE>" and the smaller line "<SUBLINE>". Left-aligned block, starting
  at about 14 % from the left edge, vertically in the upper third.
- iPhone and Apple Watch stay in the centre-right as now, fully inside the frame.
- Do not invent other text. Keep the app screens on the devices as in the original.
```

Taglines:

| Language | TAGLINE | SUBLINE |
|---|---|---|
| de | Beobachte den Energiefluss. | Auf iPhone und Apple Watch. |
| en | Track your energy flow. | On iPhone and Apple Watch. |
| da | Følg din energi. | På iPhone og Apple Watch. |
| fr | Suivez votre énergie. | Sur iPhone et Apple Watch. |
| it | Segui la tua energia. | Su iPhone e Apple Watch. |

Check the result before uploading: crop 6 % off the left and right and the top 10 %;
icon and text must still be complete. Generated text often has spelling errors —
read every letter.
