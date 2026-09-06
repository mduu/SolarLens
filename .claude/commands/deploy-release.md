---
description: Bump build number, check translations, archive, and distribute to App Store Connect for public release
---

# Deploy Release to App Store Connect

Full release pipeline: verify translations, bump build number, archive, upload to App Store Connect, and generate "What's New" notes.

## Progress Tracking

Before starting, print the full progress list. After completing each step, reprint the entire list with updated status indicators. Use exactly this format:

```
✅ Check translations (done)
👨🏻‍🔧 Bump build number (in progress)
⏳ Archive project (pending)
⏳ Verify signed build (pending)
⏳ Upload to App Store Connect (pending)
⏳ Create git tag (pending)
⏳ Generate "What's New" notes (pending)
⏳ Create GitHub release (pending)
```

Always show ALL steps. Mark completed steps with ✅, the current step with 👨🏻‍🔧, and future steps with ⏳. If a step fails, mark it with ❌.

## Step 1: Check for missing translations

Before starting the release process, verify all strings are translated.

1. Read `Shared/Localizable.xcstrings` and parse it as JSON.
2. For each key in `strings`:
   - Skip entries where `"shouldTranslate": false`.
   - Check if `localizations` contains all four target languages: `de`, `da`, `fr`, `it`.
   - A language is **missing** if it has no entry under `localizations`.
3. If there are missing translations:
   - Show the user the list of missing keys with their English text and which languages are missing.
   - Tell the user: **"There are missing translations. Please run `/translate` first to fill them in before deploying a release."**
   - **STOP here. Do not continue with the release.**
4. If all translations are present, tell the user and continue.

## Step 2: Bump the build number

1. Read `SolarLens.xcodeproj/project.pbxproj`.
2. Find all occurrences of `APP_VERSION_BUILDNO = <number>;` (there are typically 2).
3. Parse the current number, increment it by 1.
4. Replace all occurrences with the new number using the Edit tool with `replace_all: true`.
5. Tell the user the new build number.

## Step 3: Archive the project

The archive path **must** use Xcode's dated subfolder convention so the archive appears correctly in Xcode Organizer with distribution status tracking.

Run the following command to create a release archive:

```bash
ARCHIVE_PATH="$HOME/Library/Developer/Xcode/Archives/$(date '+%Y-%m-%d')/Solar Lens $(date '+%d-%m-%Y, %H.%M').xcarchive" && \
xcodebuild -project SolarLens.xcodeproj \
  -scheme "Solar Lens iOS" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination 'generic/platform=iOS' \
  archive \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=UYT5K989XD
```

Save the `ARCHIVE_PATH` value — you will need it in the next step.

If the archive fails, read the build output, analyze errors, fix them, and retry (up to 3 times).

## Step 4: Verify the signed build before uploading

`aps-environment` is `development` in the entitlements file, and Xcode rewrites it
to `production` only when it **exports** — the `.xcarchive` still says
`development`. Checking the archive would therefore always look broken; the
exported `.ipa` is the only place the real value can be read.

An app signed `development` uploads and installs happily and then silently
receives no pushes, because its token is minted against the APNs sandbox.

Export a copy purely to inspect it, then check the entitlement:

```bash
VERIFY_DIR=$(mktemp -d) && \
cat > "$VERIFY_DIR/ExportCheck.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key><string>app-store-connect</string>
	<key>destination</key><string>export</string>
	<key>teamID</key><string>UYT5K989XD</string>
	<key>signingStyle</key><string>automatic</string>
</dict>
</plist>
PLIST
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$VERIFY_DIR/ExportCheck.plist" \
  -exportPath "$VERIFY_DIR/out" -allowProvisioningUpdates >/dev/null 2>&1 && \
unzip -q "$VERIFY_DIR/out/Solar Lens.ipa" -d "$VERIFY_DIR/ipa" && \
APS=$(codesign -d --entitlements - --xml "$VERIFY_DIR/ipa/Payload/Solar Lens.app" 2>/dev/null \
  | plutil -convert xml1 -o - - \
  | python3 -c "import sys,plistlib;print(plistlib.loads(sys.stdin.buffer.read()).get('aps-environment','MISSING'))") && \
echo "aps-environment: $APS" && \
[ "$APS" = "production" ] && echo "OK — signed for production APNs" || echo "STOP — not production"
```

**If this prints anything other than `production`, do not upload.** Report it to
the user instead: the signed build would be a push-dead release. Most likely
causes are a stale provisioning profile or the App ID losing its Push
capability.

## Step 5: Distribute to App Store Connect

After a successful archive, export and upload to App Store Connect. Use the same `ARCHIVE_PATH` from Step 3:

```bash
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist ExportOptions-release.plist \
  -allowProvisioningUpdates
```

This uses `ExportOptions-release.plist` which uploads to App Store Connect for beta testers and public release (no TestFlight-internal-only restriction).

## Step 6: Create git tag

1. Read the current `APP_VERSION` from `SolarLens.xcodeproj/project.pbxproj` (e.g. `4.0.0`).
2. Create a git tag following the existing convention: `release/<APP_VERSION>` (e.g. `release/4.0.0`).

```bash
git tag release/<APP_VERSION>
git push origin release/<APP_VERSION>
```

3. The GitHub release will be created in Step 7 after the "What's New" notes are generated.

## Step 7: Generate "What's New" release notes

Generate the "What's New" text for App Store Connect.

1. Run `git log` to find all commits since the previous `release/*` tag (not the one just created, but the one before it).
2. Analyze the changes and write user-facing release notes.

**Writing guidelines:**
- Write for end-users of Solar Lens, not developers.
- Use a friendly, concise tone.
- Focus on benefits and what users will notice, not technical implementation details.
- Use plain text bullet points, no emojis.
- Keep each bullet to one sentence.
- Do NOT mention internal refactoring, code cleanup, or developer tooling changes.
- Group related changes into a single bullet where it makes sense.

**Output the notes in all five languages, one after another:**

### English
- ...

### Deutsch
- ...

### Dansk
- ...

### Français
- ...

### Italiano
- ...

The translations should feel native and natural in each language, not like machine-translated text. Match the tone used in existing App Store descriptions for Solar Lens if available.

## Step 8: Create GitHub release

Create a GitHub release based on the tag from Step 5, using the **English** "What's New" bullet list as the release body.

```bash
gh release create release/<APP_VERSION> \
  --title "Solar Lens <APP_VERSION>" \
  --notes "<English What's New bullet list>"
```

Use a HEREDOC for the notes to preserve formatting.

## Step 9: Report result

Tell the user:
- The new build number and version
- Whether the archive and upload succeeded
- The git tag that was created
- The GitHub release URL
- If the upload succeeded, that the build will appear in App Store Connect shortly
- Present the "What's New" texts so the user can copy them into App Store Connect
