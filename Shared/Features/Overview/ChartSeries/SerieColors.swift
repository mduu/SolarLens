import SwiftUI

struct SerieColors {

    static func productionColor(useAlternativeColors: Bool) -> Color {

        if useAlternativeColors {
            return .yellow
        }

        return .yellow
    }

    static func consumptionColor(useAlternativeColors: Bool) -> Color {

        if useAlternativeColors {
            return .white
        }

        return .teal
    }

    static func batteryLevelColor(useAlternativeColors: Bool) -> Color {
        if useAlternativeColors {
            return .black
        }

        return .green
    }

}
