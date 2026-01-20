import SwiftUI

struct WatchSurveyView: View {
    @Binding var isPresented: Bool
    @AppStorage("surveyForeverDismissed") var surveyForeverDismissed: Bool = false
    @AppStorage("surveyLastShownDate") var surveyLastShownDate: Double = 0.0

    var body: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.8) // Darker for Watch
                .edgesIgnoringSafeArea(.all)
                // .onTapGesture { isPresented = false } // Optional

            ScrollView {
                VStack(spacing: 10) {
                    Image("marc")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.accentColor)
                        .cornerRadius(20)
                        .padding(.top, 15)
                    
                    Text("SurveyGreeingWatchOs")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 6) {
                        Button(action: {
                            surveyForeverDismissed = true
                            withAnimation {
                                isPresented = false
                            }
                        }) {
                            Text("Close")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .tint(Color.yellow)
                    }
                    .padding(.top, 5)
                }
                .padding()
                .padding(.bottom, 20)
            }
            .background(Color.black)
            .cornerRadius(10)
            .padding(2) // Small margin
            .ignoresSafeArea()
        }
        .transition(.opacity)
    }
}

#Preview {
    WatchSurveyView(isPresented: .constant(true))
}
