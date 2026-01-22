import UIKit
import Vision

/// Result of OCR text recognition
struct OCRResult: Sendable {
    let lines: [RecognizedLine]
    let rawText: String
    let processingTime: TimeInterval

    struct RecognizedLine: Sendable {
        let text: String
        let confidence: Float
        let boundingBox: CGRect
    }
}

/// Errors that can occur during OCR processing
enum OCRError: Error, LocalizedError {
    case imageConversionFailed
    case recognitionFailed(Error)
    case noTextFound
    case cancelled

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image for text recognition"
        case .recognitionFailed(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        case .noTextFound:
            return "No text found in image"
        case .cancelled:
            return "OCR operation was cancelled"
        }
    }
}

/// Service for performing OCR using Apple's Vision framework
actor OCRService {
    private let imageProcessor: ImageProcessor
    private let supportedLanguages: [String]

    /// Initialize OCR service with language support
    /// - Parameter languages: Language codes to recognize. Defaults to English and Simplified Chinese
    init(languages: [String] = ["en-US", "zh-Hans"]) {
        self.imageProcessor = ImageProcessor()
        self.supportedLanguages = languages
    }

    /// Performs OCR on an image and returns recognized text lines
    /// - Parameters:
    ///   - image: The image to process
    ///   - preprocess: Whether to apply preprocessing for better recognition (default: true)
    /// - Returns: OCRResult containing recognized lines and metadata
    func recognizeText(in image: UIImage, preprocess: Bool = true) async throws -> OCRResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Preprocess image if requested
        let processedImage: UIImage
        if preprocess {
            processedImage = await imageProcessor.preprocessForOCR(image) ?? image
        } else {
            processedImage = image
        }

        // Convert to CGImage for Vision
        guard let cgImage = processedImage.cgImage else {
            throw OCRError.imageConversionFailed
        }

        // Perform recognition
        let lines = try await performRecognition(on: cgImage)

        guard !lines.isEmpty else {
            throw OCRError.noTextFound
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        let rawText = lines.map(\.text).joined(separator: "\n")

        return OCRResult(
            lines: lines,
            rawText: rawText,
            processingTime: processingTime
        )
    }

    /// Performs the actual Vision text recognition
    private func performRecognition(on cgImage: CGImage) async throws -> [OCRResult.RecognizedLine] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let lines = observations.compactMap { observation -> OCRResult.RecognizedLine? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return OCRResult.RecognizedLine(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }

                continuation.resume(returning: lines)
            }

            // Configure for accurate recognition (essential for crumpled thermal paper)
            request.recognitionLevel = .accurate
            request.recognitionLanguages = supportedLanguages
            request.usesLanguageCorrection = true

            // Set revision for best results
            if #available(iOS 16.0, *) {
                request.revision = VNRecognizeTextRequestRevision3
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }

    /// Quick check to verify if an image contains any text
    func containsText(in image: UIImage) async -> Bool {
        guard let cgImage = image.cgImage else { return false }

        do {
            let lines = try await performRecognition(on: cgImage)
            return !lines.isEmpty
        } catch {
            return false
        }
    }

    /// Returns supported language codes for text recognition
    static func supportedLanguages() -> [String] {
        if #available(iOS 16.0, *) {
            return (try? VNRecognizeTextRequest.supportedRecognitionLanguages(
                for: .accurate,
                revision: VNRecognizeTextRequestRevision3
            )) ?? ["en-US"]
        } else {
            return (try? VNRecognizeTextRequest.supportedRecognitionLanguages(
                for: .accurate,
                revision: VNRecognizeTextRequestRevision2
            )) ?? ["en-US"]
        }
    }
}
