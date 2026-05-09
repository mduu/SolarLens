import SwiftUI

/// Round Stop button used in every automation's running card.
///
/// Visually distinct from the iOS "close" X — this is a destructive
/// "stop the automation right now" affordance, so it gets a red fill
/// and a `stop.fill` icon, sized large enough to read as the primary
/// action surface on the card. Mirrors what we render on the Lock
/// Screen Live Activity card so the user sees the same control in
/// both places.
struct AutomationCircularCancelButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Image(systemName: "stop.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.red))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cancel automation")
    }
}

#Preview {
    AutomationCircularCancelButton(action: {})
        .padding()
}
