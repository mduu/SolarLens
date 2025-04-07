import Foundation
import AppIntents
import WidgetKit

struct EfficiencyAppIntent : WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Efficiency"
}

struct EfficiencyEntry: TimelineEntry {
    var date: Date
    var selfConsumption: Double?
    var autarky: Double?
    
    static func previewData() -> EfficiencyEntry {
        .init(
            date: Date(),
            selfConsumption: 75,
            autarky: 90
        )
    }
}

