import SwiftUI

/// The `‹ 2. Sep. 2026 ›` strip above a scrollable chart.
///
/// The chart itself scrolls freely; this header is the coarse control and,
/// just as importantly, the visible hint that there *is* history to scroll
/// back into. The trailing "now" button only appears once the user has left
/// the newest window.
struct ChartTimeHeader: View {
    let navigator: ChartTimeNavigator
    var isLoading: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            stepButton(
                systemImage: "chevron.left",
                enabled: navigator.canGoBack,
                action: navigator.stepBack
            )
            .accessibilityLabel("Previous period")

            HStack(spacing: 6) {
                Text(navigator.windowLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .contentTransition(.numericText())

                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
            .frame(maxWidth: .infinity)

            stepButton(
                systemImage: "chevron.right",
                enabled: navigator.canGoForward,
                action: navigator.stepForward
            )
            .accessibilityLabel("Next period")

            if !navigator.isAtPresent {
                Button {
                    withAnimation(.snappy) { navigator.returnToPresent() }
                } label: {
                    Image(systemName: "arrow.uturn.right.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Jump to now")
            }
        }
        .animation(.snappy, value: navigator.isAtPresent)
        .padding(.vertical, 2)
    }

    private func stepButton(
        systemImage: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 30, height: 30)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.35))
        .disabled(!enabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        ChartTimeHeader(navigator: ChartTimeNavigator(page: .day))
        ChartTimeHeader(navigator: ChartTimeNavigator(page: .week), isLoading: true)
        ChartTimeHeader(navigator: ChartTimeNavigator(page: .year))
    }
    .padding()
}
