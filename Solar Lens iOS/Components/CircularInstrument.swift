import SwiftUI

struct CircularInstrument<Content: View>: View {
    var borderColor: Color
    var label: LocalizedStringResource
    var value: String?
    var small: Bool = false
    var isTouchable: Bool = false
    var useGlowEffect: Bool = false
    @ViewBuilder let content: Content?

    init(
        borderColor: Color,
        label: LocalizedStringResource,
        value: String? = nil,
        small: Bool? = nil,
        isTouchable: Bool? = nil,
        useGlowEffect: Bool? = nil,
        @ViewBuilder content: @escaping () -> Content?
    ) {
        self.borderColor = borderColor
        self.label = label
        self.value = value
        self.small = small ?? false
        self.isTouchable = isTouchable ?? false
        self.useGlowEffect = useGlowEffect ?? false
        self.content = content()
    }

    var body: some View {
        ZStack {

            Circle()
                .fill(.white)
                .if(isTouchable) { view in
                    view.shadow(radius: 5, x: 4, y: 4)
                }
                .opacity(0.8)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 4)
                        .shadow(
                            color: borderColor.opacity(useGlowEffect ? 0.5 : 0),
                            radius: useGlowEffect ? 5 : 0,
                            x: 0,
                            y: 0
                        )
                )

            VStack(alignment: .center) {
                Text(label)
                    .font(.system(size: small ? 7 : 12, weight: .light))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)

                if value != nil {
                    Text(value!)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }

                if content != nil {
                    content
                }
            }
            .padding(.all, 4)
        }
    }
}

#Preview("Normal") {
    CircularInstrument(
        borderColor: .teal,
        label: "Solar Productions",
        value: "2.4 kW"
    ) {}
    .frame(maxWidth: 120)
}

#Preview("Touchable") {
    CircularInstrument(
        borderColor: .teal,
        label: "Solar Productions",
        value: "2.4 kW",
        isTouchable: true
    ) {}
    .frame(maxWidth: 120)
}

#Preview("Small w/o value") {
    CircularInstrument(
        borderColor: .teal,
        label: "Solar Productions"
    ) {}
    .frame(maxWidth: 80)
}

#Preview("Small w image") {
    CircularInstrument(
        borderColor: .teal,
        label: "Charger",
        small: true
    ) {
        Image(systemName: "ev.charger")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 20)
            .foregroundColor(.black)
    }
    .frame(maxWidth: 60)
}

#Preview("Small touchable") {
    CircularInstrument(
        borderColor: .teal,
        label: "Charger",
        small: true,
        isTouchable: true
    ) {
        Image(systemName: "ev.charger")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 20)
            .foregroundColor(.black)
    }
    .frame(maxWidth: 60)
}

#Preview("Small touchable & glow") {
    CircularInstrument(
        borderColor: .teal,
        label: "Charger",
        small: true,
        isTouchable: true,
        useGlowEffect: true
    ) {
        Image(systemName: "ev.charger")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 20)
            .foregroundColor(.black)
    }
    .frame(maxWidth: 60)
}
