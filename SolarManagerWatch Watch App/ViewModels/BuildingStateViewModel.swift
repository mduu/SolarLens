//
//  BuildingState.swift
//  SolarManagerWatch Watch App
//
//  Created by Marc Dürst on 29.09.2024.
//

import Foundation

class BuildingStateViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var isDirty: Bool = true;
    @Published private(set) var errorMessage = ""
    
    @Published var overviewData: OverviewData = .init()
    
    private let energyManager: EnergyManagerClient
    
    init(solarManagerClient: EnergyManagerClient = SolarManagerClient()) {
        self.energyManager = solarManagerClient
        fetchServerData()
    }
    
    func fetchServerData() {
        isLoading = true
        errorMessage = ""
        
        self.overviewData = energyManager.fetchOverviewData()
    }
}
