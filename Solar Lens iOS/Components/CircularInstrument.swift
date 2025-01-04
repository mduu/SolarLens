//
//  CircularInstrument.swift
//  Solar Lens
//
//  Created by Marc Dürst on 03.01.2025.
//

import SwiftUI

struct CircularInstrument: View {
    var borderColor: Color
    var label: LocalizedStringResource
    var value: String

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.8))
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 3)
                )

            VStack(alignment: .center) {
                Text(label)
                    .font(.system(size: 22, weight: .light))
                    .multilineTextAlignment(.center)

                Text(value)
                    .font(.system(size: 30, weight: .bold))
            }
        }
        .shadow(radius: 4, x: 4, y: 4)
        .frame(maxWidth: 150, maxHeight: 150)
    }
}

#Preview {
    CircularInstrument(
        borderColor: .teal,
        label: "Solar Productions",
        value: "2.4 kW"
    )
}
