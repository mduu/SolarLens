import SwiftUI

struct LogCountBubble: View {
    let messages: [ScenarioLogMessage]

    private var count: Int { messages.filter { $0.level != .Debug }.count }

    @State private var showingLogSheet = false

    // Count messages by level for the bubble color
    private var hasErrors: Bool {
        messages.contains { $0.level == .Error || $0.level == .Failure }
    }

    private var bubbleColor: Color {
        if count == 0 {
            return .gray
        } else if hasErrors {
            return .red
        } else {
            return .blue
        }
    }

    var body: some View {
        Button {
            showingLogSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(bubbleColor)
                    .frame(width: bubbleSize, height: bubbleSize)

                Text("\(count)")
                    .font(countFont)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
            }
        }
        .opacity(count == 0 ? 0.5 : 1.0)
        .sheet(isPresented: $showingLogSheet) {
            ScenarioLogView(messages: messages)
                .presentationDetents([.large, .medium])
        }
    }

    private var bubbleSize: CGFloat {
        switch count {
        case 0...9:
            return 32
        case 10...99:
            return 36
        case 100...999:
            return 40
        default:
            return 44
        }
    }

    private var countFont: Font {
        switch count {
        case 0...9:
            return .system(size: 14, weight: .semibold, design: .rounded)
        case 10...99:
            return .system(size: 12, weight: .semibold, design: .rounded)
        case 100...999:
            return .system(size: 10, weight: .semibold, design: .rounded)
        default:
            return .system(size: 8, weight: .semibold, design: .rounded)
        }
    }
}
