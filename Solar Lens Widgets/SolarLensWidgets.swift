//
//  SolarLensWidgets.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 23.11.2024.
//

import SwiftUI

@main
struct SolarLensWidgets: WidgetBundle {
   var body: some Widget {
       SolarProductionWidget()
       ConsumptionWidget()
       GenericWidget()
   }
}
