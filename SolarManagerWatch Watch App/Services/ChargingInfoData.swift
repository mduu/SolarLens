//
//  ChargingInfoData.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 07.12.2024.
//

import Foundation

class CharingInfoData: ObservableObject {
    @Published var totalCharedToday: Double? = nil
    @Published var currentCharging: Int? = nil
    
    init(totalCharedToday: Double?, currentCharging: Int?) {
        self.totalCharedToday = totalCharedToday
        self.currentCharging = currentCharging
    }
}
