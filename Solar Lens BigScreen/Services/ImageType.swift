internal import Foundation

enum ImageType: String {
    case logo = "logo"
    case background = "background"
}

extension ImageType {

    func toString() -> LocalizedStringResource {
        switch self {

            case .logo:
                return "Logo"

            case .background:
                return "Background"
        }
    }

}
