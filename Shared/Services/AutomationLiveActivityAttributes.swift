#if canImport(ActivityKit)
public import ActivityKit
public import Foundation

/// Attributes shared between the iOS app (which owns the
/// `Activity<AutomationLiveActivityAttributes>`) and the iOS widget
/// extension (which renders the Lock Screen card and Dynamic Island).
///
/// Designed to be **open for extension**: the shared chrome (Lock Screen
/// header, Dynamic Island compact / minimal slots) reads only from the
/// always-present fields on `ContentState`. Per-automation richness is
/// carried in `Payload`, a discriminated union with one case per `Automation`.
/// Adding a new automation only requires:
///   1. a new `Payload` case + payload struct,
///   2. an `AutomationLiveActivityProvider` conformance on the task,
///   3. a new card body view in the widget extension.
/// The coordinator and the `ActivityConfiguration` never change.
public struct AutomationLiveActivityAttributes: ActivityAttributes {

    public typealias ContentState = State

    /// Stable for the lifetime of the activity.
    public var automation: Automation

    public init(automation: Automation) {
        self.automation = automation
    }

    public struct State: Codable, Hashable {

        // MARK: - Shared chrome inputs (always present)

        /// SF Symbol shown by the chrome — Lock Screen header, Dynamic
        /// Island compact leading, minimal. Source of truth:
        /// `Automation.liveActivityIconSystemName`.
        public var iconSystemName: String

        /// When the run started — used by the chrome for "started Xm ago".
        public var startedAt: Date

        /// Primary live metric. Used by Dynamic Island compact-trailing
        /// (single line, very short) and as the headline metric in the
        /// expanded / Lock Screen body.
        public var primaryMetric: Metric

        /// Optional second metric. Shown in the expanded / Lock Screen
        /// body when present; ignored on Dynamic Island compact / minimal.
        public var secondaryMetric: Metric?

        // MARK: - Per-automation rich payload

        public var payload: Payload

        public init(
            iconSystemName: String,
            startedAt: Date,
            primaryMetric: Metric,
            secondaryMetric: Metric? = nil,
            payload: Payload
        ) {
            self.iconSystemName = iconSystemName
            self.startedAt = startedAt
            self.primaryMetric = primaryMetric
            self.secondaryMetric = secondaryMetric
            self.payload = payload
        }

        public struct Metric: Codable, Hashable {
            public var label: String
            public var value: String

            public init(label: String, value: String) {
                self.label = label
                self.value = value
            }
        }

        public enum Payload: Codable, Hashable {
            case batteryToCar(BatteryToCarPayload)
            case autoResetChargingMode(AutoResetChargingModePayload)
            case notifyOnBatteryLevel(NotifyOnBatteryLevelPayload)
        }
    }
}
#endif
