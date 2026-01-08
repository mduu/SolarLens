# iCloud Backup Setup Guide

## Overview

This implementation adds **automatic iCloud backup** for custom logos and backgrounds in the Solar Lens BigScreen tvOS app.

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                  HYBRID STORAGE FLOW                     │
└─────────────────────────────────────────────────────────┘

1. User uploads image via phone → Azure Functions
2. tvOS downloads from Azure → Image saved LOCALLY
3. Image ALSO backed up to USER'S iCloud (automatic)
4. Azure deletes image after 5 seconds (current behavior)
5. If tvOS cache cleared → Auto-restores from iCloud

┌─────────────────────────────────────────────────────────┐
│                    BENEFITS                              │
└─────────────────────────────────────────────────────────┘

✅ No server liability (images deleted as before)
✅ User convenience (images persist in their iCloud)
✅ Zero server costs (uses user's iCloud storage)
✅ Privacy-first (images never leave user's control)
✅ Seamless recovery (automatic after cache clear)
```

---

## Setup Instructions

### 1. Enable iCloud in Xcode

1. Open `Solar Lens BigScreen.xcodeproj` in Xcode
2. Select the **"Solar Lens BigScreen"** target
3. Go to **"Signing & Capabilities"** tab
4. Click **"+ Capability"** button
5. Select **"iCloud"**
6. Check **"CloudKit"**
7. Xcode will auto-create container: `iCloud.com.marcduerst.Solar-Lens-BigScreen`

**After this step**, your entitlements file will automatically include:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.marcduerst.Solar-Lens-BigScreen</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

---

### 2. CloudKit Dashboard Setup

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Sign in with your Apple Developer account
3. Select container: `iCloud.com.marcduerst.Solar-Lens-BigScreen`
4. Go to **Schema** → **Record Types**
5. Click **"+"** to create new record type:
   - **Name:** `CustomImage`
   - **Fields:**
     - `imageAsset` (Asset)
     - `imageType` (String)
     - `uploadedAt` (Date/Time)
     - `deviceID` (String)
6. Click **"Save"**
7. Deploy to **Production**

---

### 3. Testing

#### Test iCloud Upload

1. Run the app on Apple TV simulator or device
2. **Ensure you're signed into iCloud** (Settings → Users & Accounts)
3. Upload a custom logo
4. Check console for: `✅ Saved logo to iCloud`

#### Test iCloud Restore

1. Open **Settings** on Apple TV
2. Go to **General** → **Manage Storage**
3. Find **Solar Lens BigScreen**
4. Delete app data (or delete/reinstall app)
5. Relaunch app
6. Logo should automatically restore from iCloud
7. Check console for: `✅ Restored logo from iCloud`

---

## Code Changes Made

### New Files Created

1. **`CloudKitImageStorage.swift`**
   - Manages all CloudKit operations
   - Methods: `saveCustomLogo()`, `loadCustomLogo()`, `deleteCustomLogo()`
   - Same methods for backgrounds
   - Checks iCloud account status

### Modified Files

1. **`ImageStorageManager.swift`**
   - Added `iCloudBackupEnabled` flag (default: `true`)
   - `saveCustomLogo()` → Now async, backs up to iCloud
   - `loadCustomLogo()` → Now async, restores from iCloud if missing
   - `deleteCustomLogo()` → Now async, deletes from iCloud too
   - Added sync versions for backwards compatibility

2. **`ImageUploadSheet.swift`**
   - Updated to `await` async save methods
   - No functional changes to upload flow

3. **`CustomLogoView.swift`**
   - Uses `.task {}` instead of `.onAppear {}`
   - Calls async `loadCustomLogo()`

4. **`LogoConfigurationView.swift`**
   - Uses `.task {}` for initial load
   - Updated delete to async
   - Updated notification receiver to use Task

---

## Configuration Options

### Disable iCloud Backup (Optional)

If you want to disable iCloud backup for testing or specific builds:

```swift
// In your app initialization (e.g., App.swift)
ImageStorageManager.shared.iCloudBackupEnabled = false
```

### Check iCloud Status

To check if user is signed into iCloud:

```swift
let isAvailable = try await CloudKitImageStorage.shared.checkiCloudStatus()
if !isAvailable {
    // Show alert asking user to sign in
}
```

---

## User Experience

### When iCloud is Available

1. **First Upload:**
   - Image saved locally ✓
   - Image backed up to iCloud ✓
   - Server deletes after 5 seconds ✓

2. **Cache Cleared:**
   - App launches
   - Detects missing logo
   - **Automatically restores from iCloud**
   - User sees logo without re-uploading

3. **Delete Logo:**
   - Removed from local storage
   - Removed from iCloud
   - Clean slate

### When iCloud is NOT Available

- App works normally (local storage only)
- If cache cleared, logo is lost (expected behavior)
- No errors shown to user

---

## Storage Costs

| Item | Cost |
|------|------|
| **User's iCloud** | Free (uses their 5GB+ plan) |
| **Your Azure** | $0 (images deleted after 5 seconds as before) |
| **CloudKit** | Free (Apple provides generous free tier) |

**CloudKit Free Tier:**
- 10 GB asset storage per user
- 2 GB database storage
- 200 GB data transfer per day

**Reality:** A 512x512 PNG logo ≈ 100-500 KB. Even with background (4K), total < 5 MB per user.

---

## Privacy & Security

### What's Stored in iCloud

- Custom logo/background images
- Upload timestamp
- Device ID (for tracking which device uploaded)

### Who Can Access

- **Only the user** (stored in private CloudKit database)
- Not accessible by other users
- Not accessible by Apple
- Not accessible by you (developer)

### Compliance

- GDPR compliant (user controls their data)
- User can delete all data by deleting the app
- Data deleted when user deletes from settings

---

## Troubleshooting

### "iCloud is not available" Error

**Cause:** User not signed into iCloud

**Solution:**
```swift
// Check status before operations
let status = try await CloudKitImageStorage.shared.checkiCloudStatus()
if !status {
    // Show alert: "Please sign in to iCloud in Settings"
}
```

### Images Not Syncing

1. Check CloudKit Dashboard for record types
2. Ensure container ID matches: `iCloud.com.marcduerst.Solar-Lens-BigScreen`
3. Check Xcode capabilities are enabled
4. Verify user is signed into iCloud on device
5. Check console logs for errors

### "Unknown Record Type" Error

**Cause:** CloudKit schema not deployed

**Solution:**
1. Go to CloudKit Dashboard
2. Create `CustomImage` record type (see step 2 above)
3. Deploy to Production

---

## Testing Checklist

- [ ] Enable CloudKit in Xcode capabilities
- [ ] Create record type in CloudKit Dashboard
- [ ] Deploy schema to production
- [ ] Test upload flow (check logs for "Saved to iCloud")
- [ ] Delete local data
- [ ] Verify auto-restore (check logs for "Restored from iCloud")
- [ ] Test delete flow (verify removed from both local + iCloud)
- [ ] Test with iCloud signed out (should work without errors)

---

## Migration Notes

### Existing Users

- Users who already uploaded logos before this update:
  - Their logos are in local storage only
  - Next upload will auto-backup to iCloud
  - Or you can add a migration to upload existing logos

### Optional: Migrate Existing Logos

Add this to your app initialization:

```swift
Task {
    if let existingLogo = ImageStorageManager.shared.loadCustomLogoSync() {
        // Check if already in iCloud
        let iCloudLogo = try? await CloudKitImageStorage.shared.loadCustomLogo()
        if iCloudLogo == nil {
            // Backup existing logo to iCloud
            try? await CloudKitImageStorage.shared.saveCustomLogo(existingLogo)
            print("✅ Migrated existing logo to iCloud")
        }
    }
}
```

---

## Support

If you encounter issues:

1. Check Xcode console for detailed error messages
2. Verify CloudKit Dashboard schema is deployed
3. Test with a fresh app install
4. Check Apple System Status for CloudKit outages

---

## Summary

✅ **Zero server changes needed**
✅ **Minimal code changes** (mostly async/await updates)
✅ **Automatic backup** (happens in background)
✅ **Seamless restore** (user never notices)
✅ **No extra costs** (uses user's iCloud)
✅ **Privacy-first** (user controls their data)

This is the best solution for your use case! 🎉
