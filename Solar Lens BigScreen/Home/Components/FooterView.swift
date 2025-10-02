import SwiftUI

struct FooterView: View {
    var isLoading: Bool
    var lastUpdate: Date?

    var body: some View {
        VStack {
            Spacer()

            HStack {
                HStack(spacing: 10) {
                    if lastUpdate != nil {
                        Image(systemName: "timer")

                        Text(lastUpdate!.formatted(date: .omitted, time: .standard))

                    } else {
                        Text("N/A")
                    }

                    if isLoading {
                        ProgressView()
                            .font(.footnote)
                    }
                }
                .font(.footnote)

                Spacer()

                HStack(spacing: 10) {
                    PoweredBySolarLens()
                }
            }
        }
    }
}

#Preview {
    VStack {

        FooterView(
            isLoading: true,
            lastUpdate: Date()
        )

        FooterView(
            isLoading: false,
            lastUpdate: Date()
        )

        FooterView(
            isLoading: true,
            lastUpdate: nil
        )

        FooterView(
            isLoading: false,
            lastUpdate: nil
        )
    }
}
