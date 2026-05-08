import WidgetKit
import SwiftUI

/// Widget bundle for **Live Activities only**.
///
/// Lives in its own widget extension target (separate from
/// `Solar Lens iOS WidgetsExtension`) because iOS has a known issue where
/// a Live Activity bundled alongside home-screen widgets in the same
/// extension fails to render its Lock Screen card and Dynamic Island
/// content. Apple's documented workaround is to host Live Activities in a
/// dedicated widget extension. See Apple Developer Forums threads 711441,
/// 715768, 750081, 822724.
@main
struct Solar_Lens_iOS_LiveActivitiesBundle: WidgetBundle {
    var body: some Widget {
        AutomationLiveActivity()
    }
}
