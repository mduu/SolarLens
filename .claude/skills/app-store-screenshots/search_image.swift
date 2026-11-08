import AppKit
import SwiftUI

// The landscape image App Store Connect shows in search results
// ("Search results" slot, 2622 × 1206).
//
// The App Store shows only a centred part of it in the search list, so every
// element that matters sits in the middle: icon, name and tagline centred at
// the top, the iPhone centred below it and running off the bottom edge, the
// watch overlapping the phone's lower right corner.
//
// Usage:
//   swiftc -swift-version 5 -parse-as-library -O -o /tmp/search_image search_image.swift
//   /tmp/search_image <background.png> <appIcon.png> <search.json> <rawDir> <outDir>
//
// search.json: { "<lang>": { "tagline": "…", "phone": "home.png", "watch": "watch_1.png" } }
// Screenshots are read from <rawDir>/<lang>/, the watch falls back to <rawDir>/en/.
// Output: <outDir>/<lang>/search.png

struct Entry: Decodable {
    let tagline: String
    let phone: String
    let watch: String
}

let canvas = CGSize(width: 2622, height: 1206)

struct SearchImage: View {
    let background: NSImage
    let icon: NSImage
    let tagline: String
    let phone: NSImage
    let watch: NSImage

    private let phoneWidth: CGFloat = 640
    private let bezel: CGFloat = 18
    private var scale: CGFloat { phoneWidth / 402 }

    var body: some View {
        ZStack(alignment: .top) {
            Image(nsImage: background)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: canvas.width, height: canvas.height)
                .clipped()

            LinearGradient(
                colors: [Color.white.opacity(0.5), Color.white.opacity(0)],
                startPoint: .top,
                endPoint: .center
            )

            VStack(spacing: 18) {
                HStack(spacing: 28) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    Text(verbatim: "Solar Lens")
                        .font(.system(size: 110, weight: .bold, design: .rounded))
                }
                Text(tagline)
                    .font(.system(size: 54, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(Color(red: 0.16, green: 0.29, blue: 0.36))
            .padding(.top, 70)

            ZStack(alignment: .bottomTrailing) {
                phoneFrame
                watchFrame
                    .offset(x: 190, y: -40)
            }
            .padding(.top, 420)
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipped()
    }

    private var phoneFrame: some View {
        let height = phoneWidth * 2622 / 1206
        let radius = 55 * scale
        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: radius + bezel, style: .continuous)
                .fill(Color.black)
                .frame(width: phoneWidth + bezel * 2, height: height + bezel * 2)
                .shadow(color: .black.opacity(0.35), radius: 36, y: 20)
            Image(nsImage: phone)
                .resizable()
                .interpolation(.high)
                .frame(width: phoneWidth, height: height)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .padding(.top, bezel)
            Capsule()
                .fill(Color.black)
                .frame(width: 124 * scale, height: 36 * scale)
                .padding(.top, bezel + 12 * scale)
        }
        .frame(height: canvas.height - 420, alignment: .top)
    }

    private var watchFrame: some View {
        let width: CGFloat = 300
        return Image(nsImage: watch)
            .resizable()
            .interpolation(.high)
            .frame(width: width, height: width * 514 / 422)
            .clipShape(RoundedRectangle(cornerRadius: 68, style: .continuous))
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 84, style: .continuous).fill(Color(white: 0.12))
            )
            .shadow(color: .black.opacity(0.4), radius: 26, y: 14)
    }
}

@main
struct Main {
    @MainActor static func main() throws {
        let arguments = CommandLine.arguments
        guard arguments.count == 6 else {
            print("usage: search_image <background> <appIcon> <search.json> <rawDir> <outDir>")
            exit(2)
        }
        guard let background = NSImage(contentsOfFile: arguments[1]),
            let icon = NSImage(contentsOfFile: arguments[2])
        else {
            print("cannot read background or icon")
            exit(1)
        }
        let manifest = try JSONDecoder().decode(
            [String: Entry].self, from: Data(contentsOf: URL(fileURLWithPath: arguments[3]))
        )
        let raw = arguments[4]

        for (language, entry) in manifest.sorted(by: { $0.key < $1.key }) {
            guard let phone = NSImage(contentsOfFile: "\(raw)/\(language)/\(entry.phone)"),
                let watch = NSImage(contentsOfFile: "\(raw)/\(language)/\(entry.watch)")
                    ?? NSImage(contentsOfFile: "\(raw)/en/\(entry.watch)")
            else {
                print("MISSING screenshots for \(language)")
                continue
            }
            let renderer = ImageRenderer(
                content: SearchImage(
                    background: background, icon: icon, tagline: entry.tagline,
                    phone: phone, watch: watch
                )
                .environment(\.colorScheme, .light)
            )
            renderer.scale = 1
            guard let image = renderer.cgImage,
                let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
            else {
                print("FAILED \(language)")
                continue
            }
            let outDir = URL(fileURLWithPath: arguments[5]).appendingPathComponent(language)
            try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
            try png.write(to: outDir.appendingPathComponent("search.png"))
            print("ok \(language)/search.png \(image.width)x\(image.height)")
        }
    }
}
