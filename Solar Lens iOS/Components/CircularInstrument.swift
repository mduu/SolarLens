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
                .fill(.white)
                .opacity(0.8)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 4)
                )

            VStack(alignment: .center) {
                Text(label)
                    .font(.system(size: 18, weight: .light))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)

                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .frame(maxWidth: 120, maxHeight: 120)
    }
}

#Preview {
    CircularInstrument(
        borderColor: .teal,
        label: "Solar Productions",
        value: "2.4 kW"
    )
}
