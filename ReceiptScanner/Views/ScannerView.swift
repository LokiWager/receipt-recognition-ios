import SwiftUI
import VisionKit

/// SwiftUI wrapper for VNDocumentCameraViewController
struct ScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    let onScanComplete: ([UIImage]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: ScannerView

        init(_ parent: ScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            parent.onScanComplete(images)
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
            parent.dismiss()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            print("Document camera failed: \(error.localizedDescription)")
            parent.onCancel()
            parent.dismiss()
        }
    }
}

/// View model for managing the scanning workflow
@MainActor
@Observable
final class ScannerViewModel {
    private(set) var isProcessing = false
    private(set) var scannedImages: [UIImage] = []
    private(set) var ocrResults: [OCRResult] = []
    private(set) var error: Error?

    private let ocrService = OCRService()

    var hasScannedImages: Bool {
        !scannedImages.isEmpty
    }

    var totalLinesRecognized: Int {
        ocrResults.reduce(0) { $0 + $1.lines.count }
    }

    func processScannedImages(_ images: [UIImage]) async {
        scannedImages = images
        isProcessing = true
        error = nil
        ocrResults = []

        do {
            for image in images {
                let result = try await ocrService.recognizeText(in: image)
                ocrResults.append(result)
            }
        } catch {
            self.error = error
        }

        isProcessing = false
    }

    func reset() {
        scannedImages = []
        ocrResults = []
        error = nil
        isProcessing = false
    }
}

/// Main scan tab view with scanner integration
struct ScanTabView: View {
    @State private var viewModel = ScannerViewModel()
    @State private var showScanner = false
    @State private var showResults = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.isProcessing {
                    processingView
                } else if viewModel.hasScannedImages {
                    resultsPreview
                } else {
                    emptyStateView
                }
            }
            .padding()
            .navigationTitle("Scan")
            .toolbar {
                if viewModel.hasScannedImages {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            viewModel.reset()
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerView(
                    onScanComplete: { images in
                        Task {
                            await viewModel.processScannedImages(images)
                        }
                    },
                    onCancel: { }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showResults) {
                OCRResultsView(results: viewModel.ocrResults)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Scan a Receipt")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Position your receipt within the camera frame. The app will automatically detect edges and capture the image.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showScanner = true
            } label: {
                Label("Start Scanning", systemImage: "camera")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Processing Receipt...")
                .font(.headline)

            Text("Recognizing text using OCR")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var resultsPreview: some View {
        VStack(spacing: 16) {
            // Thumbnail preview
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.scannedImages.enumerated()), id: \.offset) { _, image in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 2)
                    }
                }
            }

            if let error = viewModel.error {
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.subheadline)
            } else {
                HStack {
                    Label("\(viewModel.scannedImages.count) page(s)", systemImage: "doc")
                    Spacer()
                    Label("\(viewModel.totalLinesRecognized) lines", systemImage: "text.alignleft")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    showScanner = true
                } label: {
                    Label("Rescan", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showResults = true
                } label: {
                    Label("View Results", systemImage: "text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.ocrResults.isEmpty)
            }
        }
    }
}

/// View displaying OCR results
struct OCRResultsView: View {
    let results: [OCRResult]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                    Section("Page \(index + 1)") {
                        ForEach(Array(result.lines.enumerated()), id: \.offset) { _, line in
                            HStack {
                                Text(line.text)
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                Text("\(Int(line.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if let firstResult = results.first {
                    Section("Stats") {
                        LabeledContent("Processing Time", value: String(format: "%.2fs", firstResult.processingTime))
                        LabeledContent("Total Lines", value: "\(results.reduce(0) { $0 + $1.lines.count })")
                    }
                }
            }
            .navigationTitle("OCR Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ScanTabView()
}
