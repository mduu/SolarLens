<h1>
   Solar Lens
    <a href="https://apple.co/408SKri">
    <img src="marketing/black.svg" width="96" height="auto" alt="Solar Lens Download Button">
  </a>
</h1>

<a href="https://apple.co/408SKri">
<img src="marketing/app_store_screens/final/English.png?raw=true" width="auto" height="450" alt="Solar Lens QR Code">
</a>

**Website:** [solarlens.ch](https://solarlens.ch)

## Support

Deutsch:
- Dokumentation [hier](https://github.com/mduu/SolarManagerWatch/wiki)
- Probleme melden oder Fragen: [hier](https://github.com/mduu/SolarManagerWatch/issues)
- Was ist für die App weiter geplant? [Hier](https://github.com/users/mduu/projects/2/views/1)

English:

- Find documentattion [here](https://github.com/mduu/SolarManagerWatch/wiki)
- Report issues and ask questions [here](https://github.com/mduu/SolarManagerWatch/issues)
- See what's planned [here](https://github.com/users/mduu/projects/2/views/1)

## Description

Solar Lens is a powerful app that gives you a comprehensive overview of your home's energy consumption. Easily monitor the production of solar power, total consumption, battery level, and power flow between your home and the grid.

### Key Features:

- Real-time monitoring: Track your solar energy usage in real-time and the flow of energy through your house.
- Compatibility: Works seamlessly with Solar Manager systems.
- User-friendly interface: Easily navigate and understand your energy data.

### Requirements:

- You need a login to an existing Solar Manager installation.
- watchOS 11 and iOS 18.2

### Disclaimer

- Solar Lens is not affiliated with Solar Manager AG. The app is designed to work with Solar Manager systems, but it is a separate product developed by Marc Dürst.

## Project Structure

| Directory | Description |
|-----------|-------------|
| `Solar Lens iOS/` | Primary iOS app for real-time monitoring of solar production and home energy consumption |
| `Solar Lens Watch App/` | watchOS app with compact solar and energy data visualization for Apple Watch |
| `Solar Lens BigScreen/` | tvOS app providing a full-featured dashboard for Apple TV |
| `Solar Lens Widgets/` | watchOS widgets for solar production, battery, consumption, and efficiency |
| `Solar Lens iOS Widgets/` | iOS home screen widgets for battery, solar, consumption, and timeline |
| `Shared/` | Reusable Swift components, services, state management, and UI shared across all apps |
| `Solar Lens Server/` | .NET Azure Functions backend for custom image uploads (logos/backgrounds) via QR code |
| `landingpage/` | Multi-language static marketing website ([solarlens.ch](https://solarlens.ch)) |
| `externals/` | External API specifications for Solar Manager integration |

## Technology

* Xcode
* Swift
* SwiftUI
* .NET (Azure Functions)
