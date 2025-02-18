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
                        size: 50, weight: .light)
                )
                .symbolEffect(
                    .wiggle.byLayer,
                    options: .repeat(
                        .periodic(delay: 0.7)))
        } else {
            Text("")
                .frame(minWidth: 50, minHeight: 50)
        }
    }
}

#Preview {
    ArrowGridToHouse(isActive: true)
        .frame(width: 50, height: 50)
}
