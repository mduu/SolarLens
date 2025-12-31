import UIKit
import CoreImage

/// Generates QR codes using CoreImage's built-in filter
class QRCodeGenerator {

    /// Generate a QR code image from a string
    /// - Parameters:
    ///   - string: The string to encode
    ///   - size: Desired size of the QR code
    /// - Returns: UIImage containing the QR code
    static func generate(from string: String, size: CGFloat = 500) -> UIImage? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else {
            return nil
        }

        // Scale to desired size
        let scale = size / ciImage.extent.size.width
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Generate QR code with white background
    static func generateWithBackground(from string: String, size: CGFloat = 500) -> UIImage? {
        guard let qrImage = generate(from: string, size: size) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
            qrImage.draw(at: .zero)
        }
    }
}
