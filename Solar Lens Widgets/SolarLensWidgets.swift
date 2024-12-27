import SwiftUI

@main
struct SolarLensWidgets: WidgetBundle {
   var body: some Widget {
       SolarProductionWidget()
       ConsumptionWidget()
       GenericWidget()
       BatteryWidget()
       ProductionAndConsumptionWidget()
       SolarTimelineidget()
       TodayTimelineidget()
   }
}
