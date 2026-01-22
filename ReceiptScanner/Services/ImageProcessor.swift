import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

actor ImageProcessor {
    private let context: CIContext

    init() {
        self.context = CIContext(options: [.useSoftwareRenderer: false])
    }

    /// Preprocesses an image for OCR by converting to high-contrast black and white
    /// Essential for crumpled thermal paper receipts
    func preprocessForOCR(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let processed = applyHighContrastFilter(to: ciImage)
        return renderToUIImage(processed, originalOrientation: image.imageOrientation)
    }

    /// Applies high-contrast black and white filter optimized for receipt text
    private func applyHighContrastFilter(to image: CIImage) -> CIImage {
        // Step 1: Increase contrast
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = image
        contrastFilter.contrast = 1.5
        contrastFilter.brightness = 0.05
        contrastFilter.saturation = 0

        guard let contrastOutput = contrastFilter.outputImage else { return image }

        // Step 2: Apply unsharp mask to enhance text edges
        let sharpenFilter = CIFilter.unsharpMask()
        sharpenFilter.inputImage = contrastOutput
        sharpenFilter.radius = 2.5
        sharpenFilter.intensity = 0.5

        guard let sharpenOutput = sharpenFilter.outputImage else { return contrastOutput }

        // Step 3: Apply adaptive thresholding effect using exposure adjust
        let exposureFilter = CIFilter.exposureAdjust()
        exposureFilter.inputImage = sharpenOutput
        exposureFilter.ev = 0.3

        return exposureFilter.outputImage ?? sharpenOutput
    }

    /// Renders CIImage back to UIImage preserving orientation
    private func renderToUIImage(_ ciImage: CIImage, originalOrientation: UIImage.Orientation) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: originalOrientation)
    }

    /// Crops image to remove excessive margins (useful for document camera output)
    func cropToContent(_ image: UIImage, insets: UIEdgeInsets = .zero) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        let cropRect = CGRect(
            x: insets.left,
            y: insets.top,
            width: width - insets.left - insets.right,
            height: height - insets.top - insets.bottom
        )

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Rotates image to correct orientation if needed
    func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? image
    }
}
