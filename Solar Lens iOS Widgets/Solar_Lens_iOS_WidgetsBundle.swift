//
//  Solar_Lens_iOS_WidgetsBundle.swift
//  Solar Lens iOS Widgets
//
//  Created by Marc Dürst on 09.02.2025.
//

import WidgetKit
import SwiftUI

@main
struct Solar_Lens_iOS_WidgetsBundle: WidgetBundle {
    var body: some Widget {
        Solar_Lens_iOS_Widgets()
        Solar_Lens_iOS_WidgetsControl()
        Solar_Lens_iOS_WidgetsLiveActivity()
    }
}
