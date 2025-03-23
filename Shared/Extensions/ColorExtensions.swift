import SwiftUI

extension Color {
    init?(rgbString: String?) {
        guard let rgbString else {
            return nil
        }
        
        // Handle hex format
        if rgbString.hasPrefix("#") {
            let hex = String(rgbString.dropFirst())
            var int: UInt64 = 0
            guard Scanner(string: hex).scanHexInt64(&int) else { return nil }

            let r = Double((int >> 16) & 0xFF) / 255.0
            let g = Double((int >> 8) & 0xFF) / 255.0
            let b = Double(int & 0xFF) / 255.0

            self.init(red: r, green: g, blue: b)
        }
        // Handle "255,0,0" format
        else if rgbString.contains(",") {
            let components = rgbString.components(separatedBy: ",")
            guard components.count >= 3,
                let r = Double(components[0]),
                let g = Double(components[1]),
                let b = Double(components[2])
            else { return nil }

            self.init(red: r / 255, green: g / 255, blue: b / 255)
        } else {
            return nil
        }
    }
}
