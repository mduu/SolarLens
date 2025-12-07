import AppIntents
internal import Foundation
import WidgetKit

struct GenericAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "App Icon"
}

struct GenericEntry: TimelineEntry {
    var date: Date

    static func previewData() -> GenericEntry {
        .init(date: Date())
    }
}
