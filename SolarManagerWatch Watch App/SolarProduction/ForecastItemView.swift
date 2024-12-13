import SwiftUI

struct ForecastItemView: View {
    @Binding var date: Date?
    @Binding var maxProduction: Double
    @Binding var forecast: ForecastItem?

    var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }

    var body: some View {
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

                    Text("\(forecast?.stringRange ?? "")")
                        .foregroundColor(.accent)
                        .font(.headline)

                    Text("kWh")
                        .font(.system(size: 10))

                } // :if
            } // :VStack
            .padding(4)

        } // :ZStack

    }
}

#Preview {
    ForecastItemView(
        date: .constant(Date()),
        maxProduction: .constant(11000),
        forecast: .constant(ForecastItem(min: 1.0, max: 5.3, expected: 3.4))
    )
}
