import AppKit

// Lays one language's finished screenshots side by side, as the App Store
// shows them, so the panorama can be checked for seams.
//
//   swiftc -O -o /tmp/contact_sheet contact_sheet.swift
//   /tmp/contact_sheet <finalDir>/<lang> <out.png> [height=900]

let arguments = CommandLine.arguments
guard arguments.count >= 3 else {
    print("usage: contact_sheet <dir> <out.png> [height]")
    exit(2)
}
let height = arguments.count > 3 ? CGFloat(Double(arguments[3]) ?? 900) : 900
let files = try FileManager.default.contentsOfDirectory(atPath: arguments[1])
    .filter { $0.hasSuffix(".png") }
    .sorted()
let images = files.compactMap { NSImage(contentsOfFile: "\(arguments[1])/\($0)") }
guard let first = images.first else {
    print("no images in \(arguments[1])")
    exit(1)
}
let width = first.size.width * height / first.size.height
let sheet = NSImage(size: NSSize(width: width * CGFloat(images.count), height: height))
sheet.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high
for (index, image) in images.enumerated() {
    image.draw(in: NSRect(x: CGFloat(index) * width, y: 0, width: width, height: height))
}
sheet.unlockFocus()
let rep = NSBitmapImageRep(data: sheet.tiffRepresentation!)!
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: arguments[2]))
print("ok \(arguments[2]) \(images.count) images")
