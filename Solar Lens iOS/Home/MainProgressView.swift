//

import SwiftUI

struct MainProgressView: View {
    var isLandscape: Bool = false

    var body: some View {
        Group {
            if !isLandscape {
                AppLogo()

                Spacer()

                ProgressView {
                    Text("Loading ...")
                }
                .tint(.accent)
                .controlSize(.extraLarge)
                .padding(.top, -65)

                Spacer()

            } else {
                
                ZStack {
                    HStack {
                        Spacer()
                        VStack {
                            AppLogo()
                            Spacer()
                        }
                    }
                    
                    ProgressView {
                        Text("Loading ...")
                    }
                    .tint(.accent)
                    .controlSize(.extraLarge)
                    
                }
                
            }
        }
    }

}

#Preview("Portrait") {
    MainProgressView()
}

#Preview("Landscape") {
    MainProgressView(isLandscape: true)
}
