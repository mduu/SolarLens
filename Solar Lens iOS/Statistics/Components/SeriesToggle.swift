import SwiftUI

struct SeriesToggle: View {
    var label: LocalizedStringKey
    var color: Color
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(isOn ? color : color.opacity(0.3))
                    .frame(width: 10, height: 10)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(isOn ? .primary : .secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isOn ? color.opacity(0.1) : Color.clear,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }
}
