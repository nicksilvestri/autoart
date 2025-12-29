import XCTest
@testable import Threshold

final class ThresholdFilterTests: XCTestCase {
    func testThresholdProducesExpectedPixels() throws {
        let processor = ImageProcessor()
        let width = 2
        let height = 2
        let pixels: [UInt8] = [50, 150, 200, 10]
        let image = TestImageFactory.makeGrayImage(pixels: pixels, width: width, height: height)
        let data = processor.threshold(image: image, value: 128)
        XCTAssertNotNil(data)
        XCTAssertEqual(data!, Data([0, 255, 255, 0]))
    }
}

private extension TestImageFactory {
    static func makeGrayImage(pixels: [UInt8], width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        return CGImage(width: width,
                       height: height,
                       bitsPerComponent: 8,
                       bitsPerPixel: 8,
                       bytesPerRow: width,
                       space: colorSpace,
                       bitmapInfo: CGBitmapInfo(rawValue: 0),
                       provider: provider,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: .defaultIntent)!
    }
}
