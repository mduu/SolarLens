import SwiftUI

struct AppearanceConfigurationView: View {
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
        "bg_green_gradient_4k": "Green Gradient",
        "bg_blue_gradient_4k": "Blue Gradient",
        "bg_red_gradient_4k": "Red Gradient",
    ]

    var body: some View {
        BorderBox {
            VStack(alignment: .leading) {
                Text("Appearance")
                    .font(.title3)

                HStack(alignment: .firstTextBaseline) {

                    Text("Background")
                        .frame(width: 200)

                    Picker("Select Background", selection: $backgroundImage) {
                        ForEach(AppearanceConfigurationView.availableBackgroundImages.keys.sorted(), id: \.self) { key in
                            Text(AppearanceConfigurationView.availableBackgroundImages[key]!)
                                .tag(key)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .frame(maxWidth: .infinity)

                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    VStack {
        HStack {
            AppearanceConfigurationView()
                .frame(width: 1000, height: 400)
                .border(.white)

            Spacer()
        }

        Spacer()
    }
}
