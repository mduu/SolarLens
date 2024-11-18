//
//  updateTimeStampView.swift
//  SolarManagerWatch
//
//  Created by Marc Dürst on 18.11.2024.
//

import SwiftUI

struct UpdateTimeStampView: View {
    @Binding var isStale: Bool
    @Binding var updateTimeStamp: Date?

    var body: some View {
        HStack {
            if isStale {
                Image(systemName: "exclamationmark.icloud.fill")
                    .foregroundColor(Color.red)
                    .symbolEffect(
                        .pulse.wholeSymbol,
                        options: .repeat(.continuous)
                    )
                    .font(.footnote)
            }  // :if

            Text(
                updateTimeStamp?.formatted(
                    date: .numeric, time: .standard) ?? "-"
            )
            .font(.system(size: 10))
            .foregroundColor(isStale ? .red : .gray)

        }  // :HStack
        .padding(.top, 2)
    }
}

#Preview("Normal") {
    UpdateTimeStampView(
        isStale: .constant(false),
        updateTimeStamp: .constant(Date()))
}

#Preview("Stale") {
    UpdateTimeStampView(
        isStale: .constant(true),
        updateTimeStamp: .constant(Date()))
}
