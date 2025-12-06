import SwiftUI

struct WidgetBase<Content: View>: View {
    var title: LocalizedStringResource?
    var content: Content

    @AppStorage("widgetsTransparent") var widgetsTransparent: Bool = false

    init(title: LocalizedStringResource?, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack {
            WidgetHeaderView(title: title)

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(.white)
        .glassEffect(widgetsTransparent ? .clear : .regular, in: .rect(cornerRadius: 30.0))

    }
}

#Preview {
    VStack {
        HStack {

            WidgetBase(title: "Widget Title") {
                Text("Hello Widget")
                    .font(.title)
            }
            .frame(width: 600, height: 500)

            Spacer()
        }

        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.blue.gradient)
}
