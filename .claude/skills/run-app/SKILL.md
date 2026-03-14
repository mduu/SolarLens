---
name: run-app
description: Build and run the app in the simulator via Xcode. Use when the user says "run the app", "build and run", "launch the app", "hit play", "run it", "start the app", "deploy to simulator", or similar phrases indicating they want to build and run the application.
---

# Run App via Xcode MCP

Build, install, and run the app in the simulator — equivalent to pressing the Play button in Xcode.

## Progress Tracking

Before starting, print the full progress list. After completing each step, reprint the entire list with updated status indicators. Use exactly this format:

```
👨🏻‍🔧 Connect to Xcode (in progress)
⏳ Build project (pending)
⏳ Launch app (pending)
```

Always show ALL steps. Mark completed steps with ✅, the current step with 👨🏻‍🔧, and future steps with ⏳. If a step fails, mark it with ❌.

## Procedure

### Step 1: Get Xcode workspace context

Call `mcp__xcode__XcodeListWindows` to get the current workspace `tabIdentifier`.

If no Xcode window is open, tell the user to open the project in Xcode first and stop.

### Step 2: Build the project

Call `mcp__xcode__BuildProject` with the `tabIdentifier`. This will also stop any currently attached debugger/running app. Wait for it to complete.

### Step 3: Check build results

Call `mcp__xcode__GetBuildLog` with `severity: "error"` to check for build errors.

**If NO errors** → go to Step 4.

**If there ARE errors** → fix them:

1. Read the error messages from the build log.
2. For each erroring file, use `mcp__xcode__XcodeRead` to read the file.
3. Analyze and fix the error using `mcp__xcode__XcodeUpdate` or via direct file access.
4. After fixing all errors, go back to Step 2 (rebuild).
5. Repeat up to 3 times. If errors persist after 3 fix attempts, report the remaining errors to the user and stop.

### Step 4: Launch the app in the simulator

After a successful build, trigger Xcode's Run action via AppleScript by clicking the Product > Run menu item:

```bash
osascript -e 'tell application "Xcode" to activate' -e 'delay 0.5' -e 'tell application "System Events" to tell process "Xcode" to click menu item "Run" of menu "Product" of menu bar 1'
```

This clicks Product → Run in Xcode's menu bar, which will install and launch the app on the currently selected simulator, exactly like pressing the Play button. Do NOT use keystroke-based approaches (like Cmd+R) as they may be blocked.

### Step 5: Confirm to user

Tell the user the build succeeded and the app is launching in the simulator and activate the simulator window.
