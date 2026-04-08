import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let content: String

    var body: some View {
        Group {
            if let image = makeQRImage(from: content) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.red)
            }
        }
    }

    private func makeQRImage(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
