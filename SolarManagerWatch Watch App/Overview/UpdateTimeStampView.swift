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
                    .font(.system(size: 10))
            }  // :if

            Text(GetFormattedTimestamp(timestamp: updateTimeStamp))
                .font(.system(size: 10))
                .foregroundColor(isStale ? .red : .gray)

        }  // :HStack
        .padding(.top, 1)
    }

    private func GetFormattedTimestamp(timestamp date: Date?) -> String {
        guard let date else { return "-" }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        return dateFormatter.string(from: date)
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
