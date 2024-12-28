import Foundation

class CharingInfoData: ObservableObject {
    @Published var totalCharedToday: Double? = nil
    @Published var currentCharging: Int? = nil
    
    init(totalCharedToday: Double?, currentCharging: Int?) {
        self.totalCharedToday = totalCharedToday
        self.currentCharging = currentCharging
    }
}
