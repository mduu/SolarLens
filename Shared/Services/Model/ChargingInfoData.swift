import SwiftUI

@Observable
class CharingInfoData {
    var totalCharedToday: Double? = nil
    var currentCharging: Int? = nil
    
    init(totalCharedToday: Double?, currentCharging: Int?) {
        self.totalCharedToday = totalCharedToday
        self.currentCharging = currentCharging
    }
}
