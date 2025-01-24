import SwiftUI

struct HeaderView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
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
                        .foregroundColor(colorScheme == .light ? .black : .white)
                        .font(.system(size: 24, weight: .bold))
                    
                }
                
            }  // :HStack
            Spacer()
            
        }
    }
}
