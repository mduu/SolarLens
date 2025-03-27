import SwiftUI

struct RoundChartButton: View {
    var onButtonTouch: () -> Void

    var body: some View {
        Button(action: {
            onButtonTouch()
        }) {
            ZStack {
                
                Image(systemName: "chart.line.uptrend.xyaxis.circle")
                    .resizable()
                    .scaledToFit()
                    .symbolEffect(
                        .breathe.pulse.byLayer,
                        options: .repeat(.continuous))
            }
        }
        .buttonStyle(.borderless)
        .buttonBorderShape(.circle)
        .foregroundColor(.primary)
        .frame(width: 25, height: 25)
    }
}

#Preview {
    RoundChartButton {
    }
}
