import AppIntents

struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Solar-Lens"
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
    
}
