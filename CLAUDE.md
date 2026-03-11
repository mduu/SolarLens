# Solar Lens

See [README.md](README.md) for project overview, structure, and sub-projects.

## Build

- Open `SolarLens.xcodeproj` in Xcode
- Build with: `xcodebuild -project SolarLens.xcodeproj -scheme "Solar Lens Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)' build`

## Code Style

- Swift with SwiftUI
- Follow existing patterns in `Shared/` for reusable components
- Server code uses .NET / C# (Azure Functions)
