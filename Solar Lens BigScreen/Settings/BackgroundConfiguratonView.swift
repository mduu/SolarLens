import SwiftUI

struct BackgroundConfiguratonView: View {
    @AppStorage("backgroundImage") var backgroundImage: String = availableBackgroundImages.first!.key

    static let availableBackgroundImages: [String: LocalizedStringKey] = [
        "bg_blue_sunny_clouds_4k": "Blue Sky",
        "bg_dark_sunny_clouds.4k": "Dark Sky",
    ]

    var body: some View {
        VStack {
            Text("Background")
                .font(.title3)

            Picker("Select Background", selection: $backgroundImage) {

                ForEach(BackgroundConfiguratonView.availableBackgroundImages.keys.sorted(), id: \.self) { key in
                    Text(BackgroundConfiguratonView.availableBackgroundImages[key]!)
                        .tag(key as String?)
                }

            }
            .pickerStyle(.menu)
            .padding()

            Spacer()
        }
    }
}

#Preview {
    VStack {
        HStack {
            BackgroundConfiguratonView()
                .frame(width: 600, height: 400)
                .border(.white)

            Spacer()
        }

        Spacer()
    }.background(.blue.gradient)
}
