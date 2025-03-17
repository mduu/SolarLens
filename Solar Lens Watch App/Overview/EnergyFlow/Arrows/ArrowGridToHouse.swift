//
//  ArrowGridToHouse.swift
//  Solar Lens
//
//  Created by Marc Dürst on 18.02.2025.
//

import SwiftUI

struct ArrowGridToHouse: View {
    var isActive: Bool
    
    var body: some View {
        if isActive{
            Image(systemName: "arrow.down")
                .foregroundColor(.orange)
                .font(
                    .system(
                        size: 15, weight: .light)
                )
                .symbolEffect(
                    .wiggle.byLayer,
                    options: .repeat(
                        .periodic(delay: 0.7)))
        } else {
            Text("")
                .frame(minWidth: 15, minHeight: 15)
        }
    }
}

#Preview {
    ArrowGridToHouse(isActive: true)
        .frame(width: 15, height: 15)
}
