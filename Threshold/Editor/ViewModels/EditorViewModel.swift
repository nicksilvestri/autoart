import Foundation
import SwiftUI
import UIKit

@MainActor
final class EditorViewModel: ObservableObject {
    enum BrushSize: CGFloat, CaseIterable {
        case small = 10
        case medium = 24
        case large = 48
    }

    @Published var thresholdValue: Double = 128 {
        didSet { scheduleThresholdUpdate() }
    }
    @Published var brushSize: CGFloat = BrushSize.medium.rawValue
    @Published var brushMode: BrushMode = .black
    @Published var renderedImage: CGImage?
    @Published var isSharing = false

    private let processor = ImageProcessor()
    private var baseImage: CGImage
    private var thresholded: Data?
    private var mask: BrushMask
    private var history: [BrushMask] = []
    private var redoStack: [BrushMask] = []
    private let renderer = BrushRenderer()
    private var pendingTask: Task<Void, Never>?

    init(sourceImage: CGImage) {
        self.baseImage = sourceImage
        self.mask = BrushMask(width: Int(processor.targetSize.width), height: Int(processor.targetSize.height))
        recalcThreshold(initial: true)
    }

    func setBrushSize(_ size: BrushSize) {
        brushSize = size.rawValue
    }

    func resetEdits() {
        Haptics.tap()
        mask = BrushMask(width: mask.width, height: mask.height)
        history.removeAll()
        redoStack.removeAll()
        thresholdValue = 128
        render()
    }

    func undo() {
        guard let last = history.popLast() else { return }
        redoStack.append(mask)
        mask = last
        render()
        Haptics.tap()
    }

    func redo() {
        guard let redo = redoStack.popLast() else { return }
        history.append(mask)
        mask = redo
        render()
        Haptics.tap()
    }

    func beginStroke(at point: CGPoint, in viewSize: CGSize) {
        redoStack.removeAll()
        history.append(mask)
        applyStroke(from: point, to: point, in: viewSize)
    }

    func continueStroke(from start: CGPoint, to end: CGPoint, in viewSize: CGSize) {
        applyStroke(from: start, to: end, in: viewSize)
    }

    private func applyStroke(from start: CGPoint, to end: CGPoint, in viewSize: CGSize) {
        guard let thresholded else { return }
        var workingMask = mask
        let viewport = processor.targetSize.aspectFit(in: viewSize)
        let scale = processor.targetSize.width / viewport.width
        let offset = CGPoint(x: -viewport.origin.x * scale, y: -viewport.origin.y * scale)

        let mapPoint: (CGPoint) -> CGPoint = { point in
            CGPoint(x: (point.x * scale) + offset.x, y: (point.y * scale) + offset.y)
        }

        renderer.applyStroke(mask: &workingMask,
                             from: mapPoint(start),
                             to: mapPoint(end),
                             radius: brushSize * scale,
                             mode: brushMode)
        mask = workingMask
        render(base: thresholded)
    }

    func updateBaseImageIfNeeded(_ image: CGImage) {
        baseImage = image
        recalcThreshold(initial: true)
    }

    func exportImage() -> URL? {
        guard let thresholded else { return nil }
        let merged = processor.composite(base: thresholded, mask: mask)
        guard let image = processor.makeCGImage(grayData: merged, width: mask.width, height: mask.height) else { return nil }
        let uiImage = UIImage(cgImage: image)
        guard let data = uiImage.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Threshold-Export.png")
        do {
            try data.write(to: url)
            Haptics.success()
            return url
        } catch {
            return nil
        }
    }

    private func scheduleThresholdUpdate() {
        pendingTask?.cancel()
        pendingTask = Task { [thresholdValue] in
            try? await Task.sleep(nanoseconds: 80_000_000)
            await recalcThreshold(initial: false)
        }
    }

    private func recalcThreshold(initial: Bool) {
        Task.detached { [baseImage, thresholdValue, processor] in
            let value = UInt8(clamping: Int(thresholdValue))
            let thresholded = processor.threshold(image: baseImage, value: value)
            await MainActor.run {
                self.thresholded = thresholded
                self.render()
                if initial {
                    Haptics.tap()
                }
            }
        }
    }

    private func render(base: Data? = nil) {
        guard let baseData = base ?? thresholded else { return }
        let merged = processor.composite(base: baseData, mask: mask)
        renderedImage = processor.makeCGImage(grayData: merged, width: mask.width, height: mask.height)
    }
}
