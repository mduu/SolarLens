import SwiftUI

struct WidgetHeaderView: View {
    var title: LocalizedStringResource

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
        }
    }
}

#Preview {
    VStack {
        WidgetHeaderView(title: "Now")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.blue.gradient)
}
