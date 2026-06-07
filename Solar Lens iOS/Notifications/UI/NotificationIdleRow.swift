import SwiftUI

/// Tile shown when a given notification kind is NOT currently enabled.
/// Tap to open the setup sheet.
///
/// Laid out as a compact grid tile (two columns on the Notifications
/// screen) so more kinds are visible without scrolling. The per-kind
/// description is deliberately omitted here — it is shown in the setup
/// sheet, and the icon + title carry enough meaning at tile size.
struct NotificationIdleRow: View {
    let kind: SolarLensNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Image(systemName: kind.iconSystemName)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(.orange)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityHidden(true)
                    Spacer(minLength: 0)
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                }
                Text(String(localized: kind.localizedTitleKey))
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)
                Text(String(localized: kind.localizedShortDescriptionKey))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16).fill(.regularMaterial)
            )
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .accessibilityHint(
            Text(String(localized: kind.localizedDescriptionKey))
        )
    }
}
