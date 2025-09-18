import SwiftUI

extension ScenarioLogMessageLevel {
    var symbolName: String {
        switch self {
        case .Debug:
            return "ant.fill"
        case .Success:
            return "checkmark.circle.fill"
        case .Info:
            return "info.bubble.fill"
        case .Error:
            return "exclamationmark.octagon.fill"
        case .Failure:
            return "multiply.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .Debug:
            return .purple
        case .Success:
            return .green
        case .Info:
            return .blue
        case .Error:
            return .orange
        case .Failure:
            return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .Debug:
            return "Debug"
        case .Success:
            return "Success"
        case .Info:
            return "Info"
        case .Error:
            return "Error"
        case .Failure:
            return "Failure"
        }
    }
}

extension ScenarioLogMessageLevel: CaseIterable {
    public static var allCases: [ScenarioLogMessageLevel] {
        [.Debug, .Success, .Info, .Error, .Failure]
    }
    
    public static var defaultCases: [ScenarioLogMessageLevel] {
        [.Success, .Info, .Error, .Failure]
    }
}

extension ScenarioLogMessageLevel: Hashable {}
