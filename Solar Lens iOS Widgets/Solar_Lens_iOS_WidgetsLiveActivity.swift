//
//  Solar_Lens_iOS_WidgetsLiveActivity.swift
//  Solar Lens iOS Widgets
//
//  Created by Marc Dürst on 09.02.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Solar_Lens_iOS_WidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Solar_Lens_iOS_WidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Solar_Lens_iOS_WidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Solar_Lens_iOS_WidgetsAttributes {
    fileprivate static var preview: Solar_Lens_iOS_WidgetsAttributes {
        Solar_Lens_iOS_WidgetsAttributes(name: "World")
    }
}

extension Solar_Lens_iOS_WidgetsAttributes.ContentState {
    fileprivate static var smiley: Solar_Lens_iOS_WidgetsAttributes.ContentState {
        Solar_Lens_iOS_WidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Solar_Lens_iOS_WidgetsAttributes.ContentState {
         Solar_Lens_iOS_WidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Solar_Lens_iOS_WidgetsAttributes.preview) {
   Solar_Lens_iOS_WidgetsLiveActivity()
} contentStates: {
    Solar_Lens_iOS_WidgetsAttributes.ContentState.smiley
    Solar_Lens_iOS_WidgetsAttributes.ContentState.starEyes
}
