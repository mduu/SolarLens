import SwiftUI
import _AppIntents_SwiftUI

struct SiriInfoView: View {
    fileprivate func SiriTip(for intent: any AppIntent) -> some View {
        return SiriTipView(
            intent: intent,
            isVisible: .constant(true)
        )
        .siriTipViewStyle(.automatic)
        .padding(.horizontal)
        .padding(.top)
    }

    var body: some View {
        VStack {
            Text(
                "You can use Siri to query and control your Solar Manager using Solar Lens. This works everywhere where Siri works and therefore also in CarPlay etc. \n\nHere are some examples:"
            ).padding()

            ScrollView {

                SiriTip(for: GetSolarProductionIntent())
                SiriTip(for: GetBatteryLevelIntent())
                SiriTip(for: GetConsumptionIntent())
                SiriTip(for: IsAnyCarChargingIntent())
                SiriTip(for: GetForecastIntent())
                SiriTip(for: GetEfficiencyIntent())
                SiriTip(for: GetCarInfosIntent())
                SiriTip(for: SetChargingModeIntent())

            }

            Spacer()
        }.navigationTitle("Discover Siri")
    }
}

#Preview {
    SiriInfoView()
}
