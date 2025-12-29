import CoreGraphics

extension CGSize {
    func aspectFit(in container: CGSize) -> CGRect {
        let aspectWidth = container.width / width
        let aspectHeight = container.height / height
        let scale = min(aspectWidth, aspectHeight)
        let newSize = CGSize(width: width * scale, height: height * scale)
        let origin = CGPoint(x: (container.width - newSize.width) / 2.0,
                             y: (container.height - newSize.height) / 2.0)
        return CGRect(origin: origin, size: newSize)
    }
}
