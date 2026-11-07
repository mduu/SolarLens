import AppKit
import SwiftUI

// Composes the App Store screenshots of one release, for every language.
//
// The background is ONE panorama spread across all images of a language: next
// to each other in the App Store they show one continuous picture. Image i
// gets the i-th 1242 px wide slice of the background, scaled so that the
// slices together cover it exactly.
//
// Usage:
//   swiftc -swift-version 5 -parse-as-library -O -o /tmp/compose compose.swift
//   /tmp/compose <background.png> <captions.json> <rawDir> <outDir> [verticalAnchor]
//
// captions.json:
//   { "<lang>": [
//       { "file": "home.png", "caption": "Line one\nline two" },      // iPhone
//       { "watch": ["watch_1.png", …], "caption": "…" }               // Apple Watch grid
//   ] }
// iPhone raws are read from <rawDir>/<lang>/<file> (1206×2622 simulator
// screenshots). Watch raws are read from <rawDir>/<lang>/<file>, falling back
// to <rawDir>/en/<file>. Output: <outDir>/<lang>/NN_<name>.png, 1242×2688.
//
// verticalAnchor (0…1, default 0.35) picks which band of the scaled
// panorama is used: 0 = top (sky), 1 = bottom.

struct Item: Decodable {
    let file: String?
    let watch: [String]?
    let caption: String
}

let canvas = CGSize(width: 1242, height: 2688)

/// The background scaled to cover `count` panels side by side, cropped
/// vertically at `anchor`.
func panorama(from image: NSImage, panels count: Int, anchor: CGFloat) -> CGImage {
    var rect = CGRect(origin: .zero, size: image.size)
    let source = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
    let width = canvas.width * CGFloat(count)
    let scale = max(width / CGFloat(source.width), canvas.height / CGFloat(source.height))
    let scaled = CGSize(width: CGFloat(source.width) * scale, height: CGFloat(source.height) * scale)
    let offsetY = (scaled.height - canvas.height) * anchor
    let offsetX = (scaled.width - width) / 2

    let context = CGContext(
        data: nil, width: Int(width), height: Int(canvas.height), bitsPerComponent: 8,
        bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.interpolationQuality = .high
    // Core Graphics counts y from the bottom.
    context.draw(
        source,
        in: CGRect(
            x: -offsetX,
            y: -(scaled.height - canvas.height - offsetY),
            width: scaled.width, height: scaled.height
        )
    )
    return context.makeImage()!
}

struct Panel: View {
    let background: NSImage
    let caption: String
    let content: AnyView

    var body: some View {
        ZStack(alignment: .top) {
            Image(nsImage: background)
                .resizable()
                .frame(width: canvas.width, height: canvas.height)

            // Lifts the sky behind the caption so the text stays readable.
            // Identical on every panel, so it does not break the panorama.
            LinearGradient(
                colors: [Color.white.opacity(0.55), Color.white.opacity(0)],
                startPoint: .top,
                endPoint: .center
            )

            Text(caption)
                .font(.system(size: 96, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.16, green: 0.29, blue: 0.36))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .minimumScaleFactor(0.6)
                .frame(width: 1080, height: 330)
                .padding(.top, 150)

            content
                .padding(.top, 590)
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipped()
    }
}

struct Phone: View {
    let screenshot: NSImage
    private let screenWidth: CGFloat = 868
    private let bezel: CGFloat = 22
    /// Points of the 402 pt wide device to canvas pixels.
    private var scale: CGFloat { screenWidth / 402 }
    private var screenHeight: CGFloat { screenWidth * 2622 / 1206 }

    var body: some View {
        let radius = 55 * scale
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: radius + bezel, style: .continuous)
                .fill(Color.black)
                .frame(width: screenWidth + bezel * 2, height: screenHeight + bezel * 2)
                .shadow(color: .black.opacity(0.35), radius: 40, y: 24)

            Image(nsImage: screenshot)
                .resizable()
                .interpolation(.high)
                .frame(width: screenWidth, height: screenHeight)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .padding(.top, bezel)

            // The simulator leaves the Dynamic Island out of its screenshots.
            Capsule()
                .fill(Color.black)
                .frame(width: 124 * scale, height: 36 * scale)
                .padding(.top, bezel + 12 * scale)
        }
    }
}

/// Up to six watch screenshots in two staggered columns.
struct WatchGrid: View {
    let screenshots: [NSImage]
    private let screenWidth: CGFloat = 400

    var body: some View {
        let screenHeight = screenWidth * 514 / 422
        let columns = [
            Array(screenshots.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)),
            Array(screenshots.enumerated().filter { $0.offset % 2 == 1 }.map(\.element)),
        ]
        HStack(alignment: .top, spacing: 90) {
            ForEach(0..<2, id: \.self) { column in
                VStack(spacing: 70) {
                    ForEach(Array(columns[column].enumerated()), id: \.offset) { _, image in
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: screenWidth, height: screenHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 90, style: .continuous))
                            .padding(26)
                            .background(
                                RoundedRectangle(cornerRadius: 110, style: .continuous)
                                    .fill(Color(white: 0.12))
                            )
                            .shadow(color: .black.opacity(0.35), radius: 30, y: 18)
                    }
                }
                .padding(.top, column == 1 ? 260 : 0)
            }
        }
    }
}

@main
struct Main {
    @MainActor static func main() throws {
        let arguments = CommandLine.arguments
        guard arguments.count >= 5 else {
            print("usage: compose <background> <captions.json> <rawDir> <outDir> [verticalAnchor]")
            exit(2)
        }
        guard let background = NSImage(contentsOfFile: arguments[1]) else {
            print("cannot read background \(arguments[1])")
            exit(1)
        }
        let anchor = arguments.count > 5 ? CGFloat(Double(arguments[5]) ?? 0.35) : 0.35
        let manifest = try JSONDecoder().decode(
            [String: [Item]].self, from: Data(contentsOf: URL(fileURLWithPath: arguments[2]))
        )
        let rawDir = arguments[3]

        for (language, items) in manifest.sorted(by: { $0.key < $1.key }) {
            let outDir = URL(fileURLWithPath: arguments[4]).appendingPathComponent(language)
            try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
            let strip = panorama(from: background, panels: items.count, anchor: anchor)

            for (index, item) in items.enumerated() {
                let slice = strip.cropping(
                    to: CGRect(x: CGFloat(index) * canvas.width, y: 0, width: canvas.width, height: canvas.height)
                )!
                let sliceImage = NSImage(cgImage: slice, size: canvas)

                let content: AnyView
                let name: String
                if let file = item.file {
                    guard let shot = NSImage(contentsOfFile: "\(rawDir)/\(language)/\(file)") else {
                        print("MISSING \(language)/\(file)")
                        continue
                    }
                    content = AnyView(Phone(screenshot: shot))
                    name = file
                } else if let files = item.watch {
                    let shots = files.compactMap {
                        NSImage(contentsOfFile: "\(rawDir)/\(language)/\($0)")
                            ?? NSImage(contentsOfFile: "\(rawDir)/en/\($0)")
                    }
                    guard !shots.isEmpty else {
                        print("MISSING watch screenshots for \(language)")
                        continue
                    }
                    content = AnyView(WatchGrid(screenshots: shots))
                    name = "watch.png"
                } else {
                    print("item \(index) of \(language) has neither file nor watch")
                    continue
                }

                let renderer = ImageRenderer(
                    content: Panel(background: sliceImage, caption: item.caption, content: content)
                        .environment(\.colorScheme, .light)
                )
                renderer.scale = 1
                guard let image = renderer.cgImage,
                    let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
                else {
                    print("FAILED \(language)/\(name)")
                    continue
                }
                let fileName = String(format: "%02d_%@", index + 1, name)
                try png.write(to: outDir.appendingPathComponent(fileName))
                print("ok \(language)/\(fileName) \(image.width)x\(image.height)")
            }
        }
    }
}
