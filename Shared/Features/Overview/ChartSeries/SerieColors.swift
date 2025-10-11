import SwiftUI

struct SerieColors {

    static func productionColor(useAlternativeColors: Bool) -> Color {

        if useAlternativeColors {
            return .yellow
        }

        return .yellow
    }

    static func consumptionColor(useDarkerColors: Bool) -> Color {

        if useDarkerColors {
            return .white
        }

        return .teal
    }

}
