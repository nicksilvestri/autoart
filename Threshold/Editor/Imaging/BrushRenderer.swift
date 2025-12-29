import CoreGraphics

struct BrushRenderer {
    func applyStroke(mask: inout BrushMask, from start: CGPoint, to end: CGPoint, radius: CGFloat, mode: BrushMode) {
        let distance = hypot(end.x - start.x, end.y - start.y)
        let steps = max(1, Int(distance / 0.5))
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let point = CGPoint(x: start.x + (end.x - start.x) * t,
                                y: start.y + (end.y - start.y) * t)
            paintCircle(mask: &mask, center: point, radius: radius, mode: mode)
        }
    }

    private func paintCircle(mask: inout BrushMask, center: CGPoint, radius: CGFloat, mode: BrushMode) {
        let minX = max(Int(center.x - radius), 0)
        let maxX = min(Int(center.x + radius), mask.width - 1)
        let minY = max(Int(center.y - radius), 0)
        let maxY = min(Int(center.y + radius), mask.height - 1)
        let r2 = radius * radius
        for y in minY...maxY {
            for x in minX...maxX {
                let dx = CGFloat(x) + 0.5 - center.x
                let dy = CGFloat(y) + 0.5 - center.y
                if dx * dx + dy * dy <= r2 {
                    mask.setPixel(x: x, y: y, value: mode.maskValue)
                }
            }
        }
    }
}
