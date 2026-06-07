import SwiftUI

/// Row shown when a given notification kind is NOT currently enabled.
/// Tap to open the setup sheet.
struct NotificationIdleRow: View {
    let kind: SolarLensNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: kind.iconSystemName)
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: kind.localizedTitleKey))
                        .font(.headline)
                    Text(String(localized: kind.localizedDescriptionKey))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16).fill(.regularMaterial)
            )
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}
