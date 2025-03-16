import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(proposal) }
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeight: CGFloat = 0

        for size in sizes {
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += maxHeight + spacing
                maxHeight = 0
            }
            currentX += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }

        return CGSize(width: proposal.width ?? 0, height: currentY + maxHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let sizes = subviews.map { $0.sizeThatFits(proposal) }
        let maxWidth = bounds.width
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var maxHeight: CGFloat = 0

        for index in subviews.indices {
            let size = sizes[index]
            if currentX + size.width > maxWidth {
                currentX = bounds.minX
                currentY += maxHeight + spacing
                maxHeight = 0
            }
            subviews[index].place(at: CGPoint(x: currentX, y: currentY), proposal: proposal)
            currentX += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}
