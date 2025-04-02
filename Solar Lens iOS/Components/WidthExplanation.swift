import SwiftUI

struct WidthExplanation<Content: View>: View {
    var explanation: String
    @ViewBuilder let content: Content?

    @State var isExplanationPresented: Bool = false
    @State private var preferredArrowEdge: Edge = .bottom
    @State private var anchorRect: CGRect = .zero  // Store the anchor view's rect

    init(
        explanation: String,
        @ViewBuilder content: @escaping () -> Content?
    ) {
        self.content = content()
        self.explanation = explanation
    }

    var body: some View {
        Button(action: {
            calculateArrowEdge()
            isExplanationPresented = true
        }) {
            if content != nil {
                content
            }
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: $isExplanationPresented,
            attachmentAnchor: .rect(.rect(anchorRect)),
            arrowEdge: preferredArrowEdge
        ) {
            VStack(alignment: .leading) {

                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "info.square.fill")
                    Text("Explanation")
                        .font(.headline)
                        .padding(.top, 4)
                }.foregroundColor(.blue)

                Text(explanation)
                    .padding(.top, 4)
                    .frame(width: 250)
                    .lineLimit(20)
            }
            .padding()
            .frame(maxHeight: 400)
            .presentationCompactAdaptation(.popover)
        }
    }

    func calculateArrowEdge() {
        let screenBounds = UIScreen.main.bounds
        let anchorMidX = anchorRect.midX
        let anchorMidY = anchorRect.midY

        // Determine horizontal edge
        if anchorMidX < screenBounds.width / 3 {
            preferredArrowEdge = .trailing
        } else if anchorMidX > screenBounds.width * 2 / 3 {
            preferredArrowEdge = .leading
        } else {
            // Determine vertical edge
            if anchorMidY < screenBounds.height / 2 {
                preferredArrowEdge = .bottom
            } else {
                preferredArrowEdge = .top
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {

        HStack {

            WidthExplanation(
                explanation:
                    "This is text widh a lot text so see what happens if the text must wrap around. \r\n Newline check."
            ) {
                Image(
                    systemName: "antenna.radiowaves.left.and.right.circle.fill"
                )
                .font(.system(size: 40))
                .foregroundColor(.blue)
            }

            Spacer()
        }

        HStack {
            Spacer()

            WidthExplanation(
                explanation: "This is text"
            ) {
                Image(
                    systemName: "antenna.radiowaves.left.and.right.circle.fill"
                )
                .font(.system(size: 40))
            }
        }

        Spacer()

        HStack {
            Spacer()

            WidthExplanation(
                explanation: "This is text"
            ) {
                Image(
                    systemName: "antenna.radiowaves.left.and.right.circle.fill"
                )
                .font(.system(size: 40))
            }
        }
    }
}
