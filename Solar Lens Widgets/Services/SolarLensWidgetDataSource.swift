//
//  WidgetDataSource.swift
//  Solar Lens WidgetsExtension
//
//  Created by Marc Dürst on 30.11.2024.
//

import Foundation

class SolarLensWidgetDataSource {
    private let solarManager = SolarManager()
    private var lastFetchOverviewData: Date?
    private var overviewData: OverviewData?

    func getOverviewData() async throws -> OverviewData? {
        
        if overviewData == nil || lastFetchOverviewData?.timeIntervalSinceNow ?? 0 < -10*60 {
            let data = try? await solarManager.fetchOverviewData(
                lastOverviewData: overviewData)

            overviewData = data;
        }
        
        return overviewData;
    }
}
