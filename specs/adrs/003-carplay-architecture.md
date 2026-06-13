# ADR-003: CarPlay architecture for Solar Lens

## Status

**Accepted**

## Context

Story #7 adds Apple CarPlay support to the iOS app: an energy overview, charging-mode control, and device-priority control, all on the car's head unit.

Constraints in force:

- **CarPlay is template-only.** There is no SwiftUI/UIKit drawing surface — the app may only use Apple's fixed template set (`CPTabBarTemplate`, `CPListTemplate`, `CPInformationTemplate`, …) driven by a `CPTemplateApplicationSceneDelegate`. The energy-flow diagram from iOS/watchOS cannot be reproduced; values become list rows.
- **SwiftUI App lifecycle.** `Solar_Lens_iOSApp` uses the SwiftUI `App`/`WindowGroup` lifecycle with no `UIApplicationDelegate` and no scene delegate. The iOS target builds with `INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES`, i.e. Xcode auto-generates the scene manifest — there is no `UIApplicationSceneManifest` in `Solar-Lens-Info.plist`.
- **Entitlement gating.** CarPlay needs an Apple-granted app entitlement, issued per category. Apple grants these manually; a real-hardware run is blocked until then. Simulator builds do not enforce the provisioning profile.
- **Shared, platform-agnostic data layer.** All data and control already live in `Shared/` behind `CurrentBuildingState` → `SolarManager.shared` (token auth in Keychain). CarPlay must reuse this, not add backend code.
- **Driver-safety limits.** CarPlay restricts live updates and template depth while driving; shallow hierarchies and on-demand refresh are expected.

## Decision

We decided on a **dedicated CarPlay scene with a single `@MainActor CarPlayManager` that owns its own `CurrentBuildingState` and drives a three-tab `CPTabBarTemplate`**, reusing the shared session.

Concretely:

1. **Scene manifest declared manually.** We add a full `UIApplicationSceneManifest` to `Solar-Lens-Info.plist` declaring only the `CPTemplateApplicationSceneSessionRoleApplication` role (delegate `$(PRODUCT_MODULE_NAME).CarPlaySceneDelegate`), with `UIApplicationSupportsMultipleScenes = true`. We **remove** `INFOPLIST_KEY_UIApplicationSceneManifest_Generation` from the iOS target (Debug + Release) to avoid a duplicate-manifest conflict. The phone's window scene is intentionally **not** listed — the SwiftUI `App` lifecycle keeps creating and managing it automatically; only the CarPlay scene needs an explicit delegate.

2. **Thin scene delegate, logic in a manager.** `CarPlaySceneDelegate` (a `UIResponder & CPTemplateApplicationSceneDelegate`) only forwards `didConnect` / `didDisconnect` / `sceneDidBecomeActive` to `CarPlayManager.shared`. All template construction and data flow live in the manager so the delegate stays trivial.

3. **Separate `CurrentBuildingState` instance, shared `SolarManager.shared`.** `CarPlayManager` constructs its own `CurrentBuildingState(energyManagerClient: SolarManager.shared)` rather than reaching into the `WindowGroup`'s instance. Both share the same underlying session/Keychain, so no separate login — but the CarPlay scene and the phone scene stay decoupled (no cross-scene `@Environment` plumbing, independent lifecycles). The cost is a second fetch of the same data when both scenes are live.

4. **Explicit refresh, not observation.** Instead of wiring `@Observable` tracking into a non-SwiftUI context, the manager fetches (`fetchServerData(force:)` + `fetchSolarDetails()`) on connect / scene-active and after each mutation, then rebuilds template sections via `updateSections`. This matches CarPlay's "refresh on activation / interaction, not a live timer" guidance.

5. **Only simple charging modes are selectable.** The mode list offers `ChargingMode.isSimpleChargingMode()` modes (Solar only, Solar & Tariff, Always, Off, Minimal & Solar). Modes needing extra parameters (constant current, minimum quantity, target SoC) are omitted because CarPlay templates can't host that configuration; the station's current mode is still shown in the section header even when it is one of the omitted modes.

6. **EV-charging entitlement category.** We request `com.apple.developer.carplay-charging` — the only category whose function (controlling car charging) matches the app. Recorded here because it constrains App Store review and is a hard external dependency.

## Options

### Option A: Dedicated scene + `CarPlayManager` with its own `CurrentBuildingState` *(chosen)*

**Description:** As described in Decision. Manual CarPlay-only scene manifest, thin delegate, manager owns a private building-state bound to the shared `SolarManager`.

**Pros:**
- Clean separation: the phone UI (SwiftUI) and the car UI (templates) never share view state and can't interfere.
- No change to the existing app lifecycle — SwiftUI still owns the window scene.
- Reuses 100% of the data/control layer; zero new networking.
- Explicit rebuilds are simple to reason about and align with CarPlay's update model.

**Cons:**
- A second `CurrentBuildingState` means duplicate fetches when phone + car are both active.
- Manual scene manifest + disabling auto-generation is a non-obvious project setup that must be kept in sync.

### Option B: Share the `WindowGroup`'s `CurrentBuildingState` across scenes

**Description:** Hoist the app's `CurrentBuildingState` into a shared singleton and have both the SwiftUI scene and the CarPlay manager observe it.

**Pros:**
- Single fetch path; no duplicate network calls.
- One source of truth for both UIs.

**Cons:**
- Forces the phone app's state into a global singleton purely for CarPlay's benefit, coupling two independently-lifecycled scenes.
- Requires bridging `@Observable` change notifications into the UIKit/CarPlay world anyway, which is exactly the complexity Option A avoids.
- Larger blast radius: a regression in the shared instance now affects both surfaces.

### Option C: Full UIKit app-delegate adoption

**Description:** Migrate to a `UIApplicationDelegate` + `UISceneDelegate` architecture and declare both window and CarPlay scenes explicitly.

**Pros:**
- "Textbook" multi-scene setup; both scenes configured the same way.

**Cons:**
- Rewrites the working SwiftUI lifecycle for no functional gain.
- High risk to an app already shipping widgets, live activities, background tasks, and a watch bridge that all assume the current lifecycle.

## Consequences

### Positive Impact

- CarPlay support with no backend changes and no disruption to the existing app lifecycle.
- The car and phone UIs are fully decoupled; either can change without touching the other.
- The manager is a single, testable place that maps `OverviewData` → templates.

### Negative Impact / Risks

- Duplicate data fetches when both scenes are active (minor — same 5 s-debounced path, gated by `force:` on explicit refresh).
- Real-hardware validation is blocked until Apple grants `com.apple.developer.carplay-charging`; until then only the Xcode CarPlay Simulator can be used.
- The manual scene manifest and the removed `…SceneManifest_Generation` build setting are easy to regress if the project file is regenerated; documented here and in the story.
- Omitting non-simple charging modes is a deliberate UX limitation — if users need to set e.g. target SoC from the car, that requires follow-up work.

### Effort

- Two new files (`CarPlaySceneDelegate`, `CarPlayManager`), one entitlement key, one Info.plist manifest, two build-setting removals. No new tests; verified by simulator build.

## References

- Story: [specs/stories/007-carplay-support.md](../stories/007-carplay-support.md)
- [ADR-001](./001-on-device-automation-runner.md) — server-free architecture (CarPlay reuses the same on-device data path)
- Apple: CarPlay app programming / `CPTemplateApplicationSceneDelegate`, EV-charging app entitlement
