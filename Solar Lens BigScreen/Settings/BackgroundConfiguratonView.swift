import SwiftUI

struct BackgroundConfiguratonView: View {
    @AppStorage("backgroundImageV2") var backgroundImage: String = availableBackgroundImages.first!.key

    static let availableBackgroundImages: [String: LocalizedStringKey] = [
        "bg_blue_sunny_clouds_4k": "Blue Sky",
        "bg_dark_sunny_clouds_4k": "Dark Sky",
        "bg_green_leaf_4k": "Green Leaf",
        "bg_neon_solar_4k": "Neon Solar",
        "bg_orange_gradient_4k": "Orange Gradient",
        "bg_orange_sky_4k": "Orange Sky",
        "bg_rainbow_panels_4k": "Rainbow Panels",
        "bg_solar_roof_4k": "Solar Roof",
        "bg_solar_sunset_4k": "Solar Sunset",
        "bg_sunny_forrest_4k": "Sunny Forrest",
    ]

    var body: some View {
        BorderBox {
            VStack {
                Text("Background")
                    .font(.title3)
                
                Picker("Select Background", selection: $backgroundImage) {
                    ForEach(BackgroundConfiguratonView.availableBackgroundImages.keys.sorted(), id: \.self) { key in
                        Text(BackgroundConfiguratonView.availableBackgroundImages[key]!)
                            .tag(key)
                    }
                }
                .pickerStyle(.menu)
                .padding()
            }
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
