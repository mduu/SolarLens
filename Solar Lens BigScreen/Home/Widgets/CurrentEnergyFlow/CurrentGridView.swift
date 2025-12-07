import SwiftUI

struct CurrentGridView: View {
    var currentGridInW: Int

    var body: some View {
        VStack {

            Image(systemName: "network")
                .font(.system(size: 50))

            Text(
                currentGridInW.formatWattsAsKiloWatts(widthUnit: true)
            )

        }
    }
}

#Preview {
    CurrentGridView(
        currentGridInW: 1234
    )
}
