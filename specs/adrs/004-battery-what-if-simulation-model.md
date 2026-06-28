# ADR-004: Battery what-if simulation model

## Status

**Accepted**

## Context

Story #8 ("Should I add a battery to my house?") asks the app to estimate how
much money a non-battery owner *would* have saved last year if they had owned a
battery, plus the autarky and self-consumption they would have gained, to help
them decide whether to buy one and how large it should be.

Constraints and forces:

- We already have, per interval, the user's measured production, consumption,
  grid import, and grid export (`MainDataItem` from `/v3/users/{smId}/data/range`).
- We already resolve real, time-of-use import/export tariffs via
  `TariffCalculator.resolveRate(for:config:)` (weekday- and time-slot-aware).
- The computation must run on-device, be explainable, and finish in seconds
  over a full year of hourly data (~8,760 samples).
- The result is decision support, not an accounting figure — it must be honest
  about being an estimate.

## Decision

We use a **greedy per-interval dispatch** simulation (`BatterySimulator`):

- Surplus that was exported to the grid charges the virtual battery; deficit
  that was imported from the grid is covered by discharging it.
- Bounded by usable capacity, a fixed **5% minimum state-of-charge reserve**,
  a user-adjustable **max charge/discharge power** (default 7 kW), and a
  user-adjustable **round-trip efficiency** (default 90%, applied on discharge).
- Each interval is valued with the user's **real tariffs**: avoided import is
  saved at the import rate; surplus spent charging forgoes its export revenue.
  Net savings = avoided import cost − forgone export revenue.
- Per-interval throughput is capped using the median sample spacing.

Efficiency before/after is derived from totals: self-consumed-without =
consumption − import; self-consumed-with = that + avoided import; autarky and
self-consumption percentages follow from `EnergyEfficiency`.

The UI labels the result an **estimate** and a **conservative lower bound**,
because the greedy model captures only "store surplus, cover load" — active
management (e.g. discharging to the EV before leaving so the battery can buffer
more PV, or tariff arbitrage) can save more.

## Options

### Option A: Greedy per-interval dispatch (chosen)

**Description:** Simple state machine over the interval series; charge from
surplus, discharge to cover deficit.

**Pros:**
- Explainable and fast; no training/bootstrap.
- Reuses existing tariff resolution and interval data.
- Naturally a conservative lower bound — defensible to users.

**Cons:**
- Ignores smarter strategies (load shifting, arbitrage), so it under-counts.
- Interval granularity nets out intra-interval simultaneity.

### Option B: Optimization (LP/MILP) over the year

**Description:** Solve for the cost-optimal charge/discharge schedule.

**Pros:**
- Tighter (higher) savings estimate.

**Cons:**
- Heavy dependency / complexity on-device; opaque to users; overkill for a
  "should I buy one?" estimate. A higher number that owners can't actually
  achieve passively would over-promise.

## Consequences

### Positive Impact

- Honest, explainable estimate that helps size a battery (custom capacity plus
  a preset sweep showing diminishing returns).
- Shared `BatterySimulator` / `EnergyEfficiency` are reusable (e.g. for the
  battery owners' counterfactual on the battery sheet).

### Negative Impact / Risks

- Under-counts real-world savings; mitigated by the explicit lower-bound
  footnote.
- Accuracy depends on chosen interval (see Query optimization in the story);
  hourly is the default, finer resolutions are a future opt-in.

### Effort

- Small: one simulation file plus a view model and view; no new dependencies.

## References

- Story: `specs/stories/008-should-i-add-a-battery.md`
- `Shared/Services/BatterySimulator.swift`, `Shared/Services/EnergyEfficiency.swift`
- `Shared/Services/TariffCalculator.swift`
