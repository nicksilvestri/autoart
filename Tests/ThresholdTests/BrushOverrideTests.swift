import XCTest
@testable import Threshold

final class BrushOverrideTests: XCTestCase {
    func testStrokeOverridesPixels() {
        var mask = BrushMask(width: 5, height: 5)
        let renderer = BrushRenderer()
        renderer.applyStroke(mask: &mask,
                             from: CGPoint(x: 2, y: 2),
                             to: CGPoint(x: 2, y: 2),
                             radius: 1.5,
                             mode: .white)
        let whiteCount = mask.data.filter { $0 == BrushMask.white }.count
        XCTAssertGreaterThan(whiteCount, 1)
    }
}
