import SwiftUI
import _AppIntents_SwiftUI

struct SiriDiscoveryView: View {
    @AppStorage("siriDiscoveryShownHome") var siriDiscoveryShown: Bool = true
    
    var body: some View {
        SiriTipView(
            intent: GetSolarProductionIntent(),
            isVisible: $siriDiscoveryShown
        )
        .siriTipViewStyle(.dark)
        .scenePadding()
    }
}
