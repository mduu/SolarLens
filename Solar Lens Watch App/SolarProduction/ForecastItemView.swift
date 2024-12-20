import SwiftUI

struct ForecastItemView: View {
    @Binding var date: Date?
    @Binding var maxProduction: Double
    @Binding var forecast: ForecastItem?
    @Binding var small: Bool?

    var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }

    var body: some View {
        let isSmall = small ?? false
        
        ZStack {
            
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.accentColor.opacity(0.1))
                .frame(maxWidth: 50)

            VStack {
                if date != nil {

                    Text(
                        date!,
                        formatter: shortDateFormatter
                    )
                    .font(isSmall ? .system(size: 10) : .body)

                    Text("\(forecast?.stringRange ?? "")")
                        .foregroundColor(.accent)
                        .font(.headline)

                    if !isSmall {
                        Text("kWh")
                            .font(.system(size: 10))
                    }

                } // :if
            } // :VStack
            .padding(4)

        } // :ZStack

    }
}

#Preview("Normal") {
    ForecastItemView(
        date: .constant(Date()),
        maxProduction: .constant(11000),
        forecast: .constant(ForecastItem(min: 1.0, max: 5.3, expected: 3.4)),
        small: .constant(false)
    )
}

#Preview("Small") {
    ForecastItemView(
        date: .constant(Date()),
        maxProduction: .constant(11000),
        forecast: .constant(ForecastItem(min: 1.0, max: 5.3, expected: 3.4)),
        small: .constant(true)
    )
}
