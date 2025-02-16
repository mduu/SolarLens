import SwiftUI

struct HeaderView: View {
    @Environment(CurrentBuildingState.self) var buildingState:
        CurrentBuildingState
    @Environment(\.colorScheme) var colorScheme
    @State var showLogoutConfirmation: Bool = false

    var body: some View {
        Grid {

            GridRow {
                HStack {
                    Text("")
                    Spacer()
                }

                HStack(alignment: .center) {
                    Image("solarlens")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(5)
                        .frame(maxWidth: 50)

                    VStack(alignment: .leading) {

                        Text("Solar")
                            .foregroundColor(.accent)
                            .font(.system(size: 24, weight: .bold))

                        Text("Lens")
                            .foregroundColor(
                                colorScheme == .light ? .black : .white
                            )
                            .font(.system(size: 24, weight: .bold))

                    }

                }  // :HStack

                HStack{
                    Spacer()
                    
                    Button(
                        "Log out",
                        systemImage: "iphone.and.arrow.right.outward"
                    ) {
                        showLogoutConfirmation = true
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .foregroundColor(.primary)
                    .font(.system(size: 24))
                    .confirmationDialog(
                        "Are you sure to log out?",
                        isPresented: $showLogoutConfirmation
                    ) {
                        Button("Confirm") {
                            buildingState.logout()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                    .padding(.trailing, 30)
                }

            }  // :VStack
        }
    }
}

#Preview {
    VStack {
        HeaderView()
            .environment(
                CurrentBuildingState.fake(
                    overviewData: OverviewData.fake()))
        
        Spacer()
    }
}
