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
    
    @Published private(set) var overviewData: OverviewData = .init()
    
    private let solarManagerClient: SolarManagerClient
    
    init(solarManagerClient: SolarManagerClient = SolarManagerClient()) {
        self.solarManagerClient = solarManagerClient
    }
    
    func fetchServerData() {
        isLoading = true
        errorMessage = ""
        
        self.overviewData = solarManagerClient.fetchOverviewData()
    }
}
