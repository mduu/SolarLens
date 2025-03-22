import SwiftUI

struct ConditionalFrame: ViewModifier {
    let widthSmallWatch: CGFloat
    let heightSmallWatch: CGFloat
    let widthLargeWatch: CGFloat
    let heightLargeWatch: CGFloat

    func body(content: Content) -> some View {
        let isLargeWatch =
            WKInterfaceDevice.current().screenBounds.height >= 220  // 45mm watches logical height

        if isLargeWatch {
            content
                .frame(
                    width: widthLargeWatch,
                    height: heightLargeWatch
                )
        } else {
            content
                .frame(
                    width: widthSmallWatch,
                    height: heightSmallWatch
                )
        }
    }
}
