import WidgetKit
import SwiftUI

@main
struct Solar_Lens_iOS_WidgetsBundle: WidgetBundle {
    var body: some Widget {
        BatteryWidget()
        SolarProductionWidget()
        ConsumptionWidget()
        TodayTimelineidget()
        EfficiencyWidget()
        ForecastWidget()
    }
}
