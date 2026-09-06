---
description: Bump build number, archive, and distribute to TestFlight (internal only)
---

# Deploy to TestFlight (Internal Only)

Increment the build number, create a release archive, and upload to TestFlight for internal testing.

## Progress Tracking

Before starting, print the full progress list. After completing each step, reprint the entire list with updated status indicators. Use exactly this format:

```
👨🏻‍🔧 Bump build number (in progress)
⏳ Archive project (pending)
⏳ Verify signed build (pending)
⏳ Upload to TestFlight (pending)
```

Always show ALL steps. Mark completed steps with ✅, the current step with 👨🏻‍🔧, and future steps with ⏳. If a step fails, mark it with ❌.

## Step 1: Bump the build number

1. Read `SolarLens.xcodeproj/project.pbxproj`.
2. Find all occurrences of `APP_VERSION_BUILDNO = <number>;` (there are typically 2).
3. Parse the current number, increment it by 1.
4. Replace all occurrences with the new number using the Edit tool with `replace_all: true`.
5. Tell the user the new build number.

## Step 2: Archive the project

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

## Step 3: Verify the signed build before uploading

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

## Step 4: Distribute to TestFlight

After a successful archive, export and upload to App Store Connect for TestFlight internal testing. Use the same `ARCHIVE_PATH` from Step 2:

```bash
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist ExportOptions-testflight.plist \
  -allowProvisioningUpdates
```

This uses `ExportOptions-testflight.plist` at the project root which is configured for `testFlightInternalTestingOnly`.

## Step 5: Report result

Tell the user:
- The new build number
- Whether the archive and upload succeeded
- If the upload succeeded, that the build will appear in TestFlight shortly for internal testers
