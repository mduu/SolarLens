// 

import SwiftUI
import _AppIntents_SwiftUI

struct SiriOnboardingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Siri Integration")
                .font(.title)
                .padding(.bottom)
                .bold()
            
            Text("Did you know Solar Lens has built-in Siri integration?")
                .font(.headline)
            
            Text("You can talk to Siri to get informaiton from you Solar Manager installtion or to control thinks like car charging mode.")
            
            Text("You can ask Siri thinkg like the following:")
            
            SiriTipView(intent: GetSolarProductionIntent())
                .siriTipViewStyle(.dark)
                .padding(.vertical)
            
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "lightbulb.max.fill")
                    .foregroundColor(.yellow)
                VStack(alignment: .leading) {
                    Text("Tip:").bold()
                    Text("You need to add the words 'in Solar Lens' to your Siri commands.")
                }
                .padding(.trailing)
            }
            .padding(.vertical)
            .background(.gray.opacity(0.1))
            .frame(maxWidth: .infinity)
            
            Text("You find a lot more samples in the settings menu of Solar Lens.")
                .padding(.bottom)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    SiriOnboardingView()
}
