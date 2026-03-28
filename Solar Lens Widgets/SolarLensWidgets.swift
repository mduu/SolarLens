import SwiftUI

@main
struct SolarLensWidgets: WidgetBundle {
   var body: some Widget {
       SolarProductionWidget()
       ConsumptionWidget()
       BatteryWidget()
       ProductionAndConsumptionWidget()
       SolarTimelineidget()
       TodayTimelineidget()
       ForecastWidget()
       EfficiencyWidget()
   }
}
