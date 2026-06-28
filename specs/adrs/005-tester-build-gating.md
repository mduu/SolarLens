# ADR-005: Tester-build detection for feature gating

## Status

**Accepted**

## Context

Story #8 requires the battery what-if simulator to be shown to **non-battery
owners only in production**, but to **everyone during testing** (so it can be
exercised on real installations that actually have battery history).

The codebase previously had no notion of "is this a tester build?" — the only
environment switch was `#if DEBUG` (used for the backend URL in
`ServerUrls.swift`). DEBUG alone does not cover TestFlight, which ships a
Release build.

## Decision

Add a small `TesterBuild` helper (`Shared/Services/TesterBuild.swift`) exposing
`TesterBuild.isActive`:

- `true` when compiled `#if DEBUG` (local development), **or**
- the install carries a **sandbox App Store receipt**
  (`Bundle.main.appStoreReceiptURL.lastPathComponent == "sandboxReceipt"`),
  which is how TestFlight installs are distinguished from production App Store
  installs.

Feature gating becomes `isTesterBuild || !hasAnyBattery`.

## Options

### Option A: Sandbox receipt + DEBUG (chosen)

**Pros:**
- No dependencies; works in DEBUG and TestFlight; production stays gated.
- Self-contained and easy to reuse for future in-development features.

**Cons:**
- `appStoreReceiptURL` is deprecated on newer OSes (still functional). If it is
  removed, migrate to StoreKit 2 `AppTransaction.shared.environment`.

### Option B: StoreKit 2 `AppTransaction`

**Pros:**
- The forward-looking API; not deprecated.

**Cons:**
- Async, can fail/needs network in edge cases, heavier for a simple boolean.
  Deferred until the receipt URL is actually removed.

### Option C: A build-time flag / separate scheme

**Pros:**
- Explicit.

**Cons:**
- Doesn't distinguish TestFlight from production without a separate
  distribution; error-prone to manage per release.

## Consequences

### Positive Impact

- One reusable gate for "tester-only" exposure of in-development features.
- Production behaviour matches the story (non-owners only).

### Negative Impact / Risks

- Uses a deprecated API; revisit if Apple removes `appStoreReceiptURL`
  (migration path: StoreKit 2 `AppTransaction`).

### Effort

- Minimal: one helper file.

## References

- Story: `specs/stories/008-should-i-add-a-battery.md`
- `Shared/Services/TesterBuild.swift`
