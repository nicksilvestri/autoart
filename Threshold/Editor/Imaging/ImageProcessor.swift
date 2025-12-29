import CoreGraphics
import CoreImage
import UIKit

struct ImageProcessor {
    let targetSize = CGSize(width: 2000, height: 2500)
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    func prepareWorkingImage(from cgImage: CGImage) -> CGImage? {
        guard let cropped = centerCrop(image: cgImage, aspectRatio: targetSize.width / targetSize.height) else { return nil }
        return scale(image: cropped, to: targetSize)
    }

    func centerCrop(image: CGImage, aspectRatio: CGFloat) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let currentAspect = width / height
        var cropWidth = width
        var cropHeight = height

        if currentAspect > aspectRatio {
            cropWidth = height * aspectRatio
        } else {
            cropHeight = width / aspectRatio
        }

        let x = (width - cropWidth) / 2.0
        let y = (height - cropHeight) / 2.0
        let rect = CGRect(x: x, y: y, width: cropWidth, height: cropHeight).integral
        return image.cropping(to: rect)
    }

    func scale(image: CGImage, to size: CGSize) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: Int(size.width) * 4,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: size))
        return context.makeImage()
    }

    func threshold(image: CGImage, value: UInt8) -> Data? {
        guard let gray = grayscale(image: image) else { return nil }
        var thresholded = gray
        for i in 0..<thresholded.count {
            thresholded[i] = thresholded[i] >= value ? 255 : 0
        }
        return thresholded
    }

    func grayscale(image: CGImage) -> Data? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var buffer = Data(count: image.width * image.height)
        let bytesPerRow = image.width
        return buffer.withUnsafeMutableBytes { ptr -> Data? in
            guard let context = CGContext(data: ptr.baseAddress,
                                          width: image.width,
                                          height: image.height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: bytesPerRow,
                                          space: colorSpace,
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return Data(ptr)
        }
    }

    func makeCGImage(grayData: Data, width: Int, height: Int) -> CGImage? {
        guard grayData.count == width * height else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceGray()
        return grayData.withUnsafeBytes { ptr -> CGImage? in
            guard let provider = CGDataProvider(data: Data(ptr) as CFData) else { return nil }
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
                           intent: .defaultIntent)
        }
    }

    func composite(base: Data, mask: BrushMask) -> Data {
        var output = base
        for i in 0..<mask.data.count {
            let maskValue = mask.data[i]
            if maskValue != BrushMask.neutral {
                output[i] = maskValue
            }
        }
        return output
    }
}
