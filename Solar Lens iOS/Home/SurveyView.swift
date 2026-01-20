import SwiftUI

struct SurveyView: View {
    @Binding var isPresented: Bool
    
    @AppStorage("surveyForeverDismissed") var surveyForeverDismissed: Bool = false
    @AppStorage("surveyLastShownDate") var surveyLastShownDate: Double = 0.0
    
    var body: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Optional: Tap background to dismiss behavior
                }
            
            // Card Content
            VStack(spacing: 24) {

                HStack(alignment: .top) {
                    // Avatar
                    Image("marc")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.accentColor)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .padding(.top, 20)

                    // Text
                    Text("Hi! I’m Marc, the developer of Solar Lens. I’m currently planning the next features and would love your input. Could you spare 3 minutes for a quick survey? Your feedback helps me build a better app for you ☀️\n\nThanks for your support! — Marc")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Buttons
                VStack(spacing: 16) {
                    Link(destination: URL(string: "https://forms.cloud.microsoft/r/Rej2bBYWGY")!) {
                        Text("Open Survey")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.yellow)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        // Later: Show again after 24 hours
                        surveyLastShownDate = Date().timeIntervalSince1970
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("Later")
                            .font(.headline)
                            .foregroundColor(.yellow.darken())
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // No Thanks: Never show again
                        surveyForeverDismissed = true
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("No thanks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(40) // Margin from screen edges
        }
        .transition(.opacity) // Smooth fade in/out
    }
}

#Preview {
    SurveyView(isPresented: .constant(true))
}
