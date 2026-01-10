import SwiftUI

struct AppearanceConfigurationView: View {
    @AppStorage("backgroundImageV2") var backgroundImage: String = availableBackgroundImages.first!.key
    @AppStorage("widgetsDarkmode") var widgetsDarkMode: Bool = false

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
        "bg_black_gradient_4k": "Black Gradient",
        "bg_dark_panels_4k": "Dark Panels",
        "bg_eclipse_4k": "Dark Eclipse",
        "bg_earth_4k": "Earth",
    ]

    var body: some View {
        BorderBox {
            VStack(alignment: .leading, spacing: 30) {
                Text("Appearance")
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("Background")
                        .frame(width: 500, alignment: .leading)

                    Picker("Select Background", selection: $backgroundImage) {
                        ForEach(AppearanceConfigurationView.availableBackgroundImages.keys.sorted(), id: \.self) {
                            key in
                            Text(AppearanceConfigurationView.availableBackgroundImages[key]!)
                                .tag(key)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack(alignment: .center, spacing: 12) {
                    Text("Darken widgets")
                        .frame(width: 500, alignment: .leading)

                    Toggle("", isOn: $widgetsDarkMode)
                        .labelsHidden()
                }

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: "info.circle")
                    Text(
                        "Please note that the effect highly depends if the tvOS system setting is 'dark' or 'light' mode. Try change the system setting as well."
                    )
                    .font(.footnote)
                }

                HStack (alignment: .top) {
                    LogoConfigurationView()
                    BackgroundConfigurationView()
                }
                .padding(.top, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    VStack {
        HStack {
            AppearanceConfigurationView()
                .frame(width: 1000)

            Spacer()
        }

        Spacer()
    }
}
