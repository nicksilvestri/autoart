import CoreGraphics

struct BrushMask: Equatable {
    private(set) var data: [UInt8]
    let width: Int
    let height: Int

    static let neutral: UInt8 = 128
    static let black: UInt8 = 0
    static let white: UInt8 = 255

    init(width: Int, height: Int, fill: UInt8 = neutral) {
        self.width = width
        self.height = height
        self.data = Array(repeating: fill, count: width * height)
    }

    func pixel(x: Int, y: Int) -> UInt8 {
        guard x >= 0 && y >= 0 && x < width && y < height else { return Self.neutral }
        return data[y * width + x]
    }

    mutating func setPixel(x: Int, y: Int, value: UInt8) {
        guard x >= 0 && y >= 0 && x < width && y < height else { return }
        data[y * width + x] = value
    }

    func applyingMask(from other: BrushMask) -> BrushMask {
        var copy = self
        copy.data = other.data
        return copy
    }
}

enum BrushMode {
    case black
    case white

    var maskValue: UInt8 { self == .white ? BrushMask.white : BrushMask.black }
}
