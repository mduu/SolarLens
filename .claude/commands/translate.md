---
description: Find and fill missing translations in Localizable.xcstrings for German, Danish, French, and Italian
---

# Translate Missing Strings

Find missing translations in `Shared/Localizable.xcstrings` and add German (de), Danish (da), French (fr), and Italian (it) translations.

## Progress Tracking

Before starting, print the full progress list. After completing each step, reprint the entire list with updated status indicators. Use exactly this format:

```
👨🏻‍🔧 Build project (in progress)
⏳ Find missing translations (pending)
⏳ Review with user (pending)
⏳ Translate strings (pending)
⏳ Verify build (pending)
⏳ Show results (pending)
```

Always show ALL steps. Mark completed steps with ✅, the current step with 👨🏻‍🔧, and future steps with ⏳. If a step fails, mark it with ❌.

## Procedure

### Step 1: Build the project

Build the project first so Xcode extracts any new string keys into the xcstrings file.

Use `mcp__xcode__XcodeListWindows` to get the `tabIdentifier`, then call `mcp__xcode__BuildProject`.

If the build fails, check errors via `mcp__xcode__GetBuildLog`, fix them, and rebuild (up to 3 times).

### Step 2: Find missing translations

After a successful build, read `Shared/Localizable.xcstrings` and parse it as JSON.

For each key in `strings`:
- Skip entries where `"shouldTranslate": false`.
- Check if `localizations` contains all four target languages: `de`, `da`, `fr`, `it`.
- A language is **missing** if it has no entry at all under `localizations`.
- Collect all keys that are missing one or more languages.

For each missing key, determine the English source text:
- If `localizations.en.stringUnit.value` exists, use that.
- Otherwise, use the key itself as the English text (this is how SwiftUI string catalogs work).

### Step 3: Present missing translations for confirmation

Show the user a numbered list of all missing keys with their English text, e.g.:

```
Found X keys with missing translations:

1. "Statistics" (en: "Statistics") — missing: de, da, fr, it
2. "From" (en: "From") — missing: de, da, fr, it
...
```

Ask the user: **"These are the English texts that will be translated. Should I proceed?"**

Wait for confirmation before continuing. Do NOT proceed without user approval.

### Step 4: Translate and insert

For each missing key and each missing language, produce a natural, context-appropriate translation.

**Translation guidelines:**
- These are UI labels for a solar energy monitoring app (Solar Lens).
- Keep translations concise — they appear on iOS, watchOS, and tvOS screens.
- Preserve any format specifiers (`%@`, `%.0f`, `%lld`, etc.) exactly as they appear in the English text.
- Preserve any SwiftUI string interpolation patterns (e.g., `\(variableName)`).
- Match the tone and style of existing translations in the file.
- For technical solar/energy terms, use the established translations already in the file for consistency.

Insert the translations into the xcstrings JSON. Each translation entry follows this structure:

```json
"<language_code>": {
  "stringUnit": {
    "state": "translated",
    "value": "<translated text>"
  }
}
```

Add the missing language entries into the `localizations` object of each key. If a key has no `localizations` object yet, create one.

Use the Edit tool to make the changes to `Shared/Localizable.xcstrings`. Be careful to maintain valid JSON.

### Step 5: Build to verify

Build the project again using `mcp__xcode__BuildProject` to verify the xcstrings file is valid and there are no build errors.

If errors occur, fix them and rebuild.

### Step 6: Show results

Present the translated texts to the user in a markdown table:

```
| Key | English | Deutsch | Dansk | Français | Italiano |
|-----|---------|---------|-------|----------|----------|
| ... | ...     | ...     | ...   | ...      | ...      |
```

Report the total number of translations added.
