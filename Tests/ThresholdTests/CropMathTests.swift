import XCTest
@testable import Threshold

final class CropMathTests: XCTestCase {
    func testWideImageCropsToPortraitCenter() throws {
        let processor = ImageProcessor()
        let image = TestImageFactory.makeSolid(width: 4000, height: 2000)
        let cropped = processor.centerCrop(image: image, aspectRatio: processor.targetSize.width / processor.targetSize.height)
        XCTAssertNotNil(cropped)
        if let cropped {
            XCTAssertEqual(cropped.width, 1600)
            XCTAssertEqual(cropped.height, 2000)
        }
    }

    func testTallImageCropsToPortraitCenter() throws {
        let processor = ImageProcessor()
        let image = TestImageFactory.makeSolid(width: 1800, height: 3000)
        let cropped = processor.centerCrop(image: image, aspectRatio: processor.targetSize.width / processor.targetSize.height)
        XCTAssertNotNil(cropped)
        if let cropped {
            XCTAssertEqual(cropped.width, 1800)
            XCTAssertEqual(cropped.height, 2250)
        }
    }
}

enum TestImageFactory {
    static func makeSolid(width: Int, height: Int, value: UInt8 = 128) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var data = Data(repeating: value, count: width * height)
        let provider = CGDataProvider(data: data as CFData)!
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
