internal import Foundation
import SwiftUI

struct StandardTheme : ColorTheme {
    static var id: String = "theme.standard"
    static var name: LocalizedStringResource = "Standard"
    static var description: String = "A simple standard theme"

    static var primaryColor: Color = Color.white
    static var backgroundTintColor: Color = Color.blue
}
