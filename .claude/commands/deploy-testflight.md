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

## Step 3: Distribute to TestFlight

After a successful archive, export and upload to App Store Connect for TestFlight internal testing. Use the same `ARCHIVE_PATH` from Step 2:

```bash
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist ExportOptions-testflight.plist \
  -allowProvisioningUpdates
```

This uses `ExportOptions-testflight.plist` at the project root which is configured for `testFlightInternalTestingOnly`.

## Step 4: Report result

Tell the user:
- The new build number
- Whether the archive and upload succeeded
- If the upload succeeded, that the build will appear in TestFlight shortly for internal testers
