import SwiftUI

struct SunTimesView: View {
    var sunrise: Date?
    var sunset: Date?
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 16) {
            if let sunrise {
                HStack(spacing: 4) {
                    Image(systemName: "sunrise.fill")
                        .symbolRenderingMode(.multicolor)
                    Text(timeFormatter.string(from: sunrise))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            if let sunset {
                HStack(spacing: 4) {
                    Image(systemName: "sunset.fill")
                        .symbolRenderingMode(.multicolor)
                    Text(timeFormatter.string(from: sunset))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.top, 0)
    }
}

#Preview {
    SunTimesView(sunrise: Date(), sunset: Date())
}
