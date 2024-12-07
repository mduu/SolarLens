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
    @Binding var isLoading: Bool

    var body: some View {
        ZStack {
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
            
            if isLoading {
                HStack {
                    Image(systemName: "arrow.trianglehead.2.counterclockwise")
                        .symbolEffect(
                            .rotate.byLayer, options: .repeat(.continuous))
                        .font(.system(size: 6))
                        .foregroundColor(.gray)
                        .padding(.leading, 20)
                    
                    Spacer()
                } // :HStack
            }
        } // :ZStack
    }

    private func GetFormattedTimestamp(timestamp date: Date?) -> String {
        guard let date else { return "-" }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy HH:mm:ss"
        return dateFormatter.string(from: date)
    }
}

#Preview("Normal") {
    UpdateTimeStampView(
        isStale: .constant(false),
        updateTimeStamp: .constant(Date()),
        isLoading: .constant(false))
}

#Preview("Stale") {
    UpdateTimeStampView(
        isStale: .constant(true),
        updateTimeStamp: .constant(Date()),
        isLoading: .constant(false))
}

#Preview("IsLoading") {
    UpdateTimeStampView(
        isStale: .constant(true),
        updateTimeStamp: .constant(Date()),
        isLoading: .constant(true))
}
