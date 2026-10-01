import Foundation
import ImageIO
import UniformTypeIdentifiers

actor PhotoImport {
  func copy(_ url: URL) throws -> URL {
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    guard size > 0, size <= 20_000_000 else { throw PhotoError.invalid }
    let data = try Data(contentsOf: url)
    guard data.count <= 20_000_000, let source = CGImageSourceCreateWithData(data as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = properties[kCGImagePropertyPixelWidth] as? Int,
      let height = properties[kCGImagePropertyPixelHeight] as? Int,
      width > 0, height > 0, width <= 50_000_000 / height,
      let image = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: 1600,
        ] as CFDictionary)
    else { throw PhotoError.invalid }
    let output = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
    guard
      let writer = CGImageDestinationCreateWithURL(
        output as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
    else { throw PhotoError.invalid }
    CGImageDestinationAddImage(
      writer, image, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
    guard CGImageDestinationFinalize(writer) else { throw PhotoError.invalid }
    return output
  }
  func remove(_ url: URL) { try? FileManager.default.removeItem(at: url) }
}
enum PhotoError: LocalizedError {
  case invalid
  var errorDescription: String? { "Choose an image under 20 MB and 50 megapixels." }
}
