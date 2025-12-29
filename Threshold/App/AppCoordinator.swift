import SwiftUI
import AVFoundation

@MainActor
final class AppCoordinator: ObservableObject {
    enum Route {
        case camera
        case editor(CGImage)
        case permissionDenied
        case failure
    }

    @Published var route: Route = .camera
    @Published var cameraService = CameraService()

    func start() {
        if ProcessInfo.processInfo.environment["UITESTING"] == "1" {
            loadDebugImage()
            return
        }
        Task {
            let status = await cameraService.checkAuthorization()
            switch status {
            case .authorized:
                route = .camera
            case .notDetermined:
                let granted = await cameraService.requestAccess()
                route = granted ? .camera : .permissionDenied
            case .denied, .restricted:
                route = .permissionDenied
            @unknown default:
                route = .permissionDenied
            }
        }
    }

    func handleCapture(result: Result<CGImage, Error>) {
        switch result {
        case .success(let image):
            route = .editor(image)
        case .failure:
            route = .failure
        }
    }

    func resetToCamera() {
        route = .camera
        start()
    }

    private func loadDebugImage() {
        let size = CGSize(width: 200, height: 250)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: Int(size.width) * 4,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            route = .failure
            return
        }
        for y in 0..<Int(size.height) {
            for x in 0..<Int(size.width) {
                let gray = UInt8((Double(x) / Double(size.width - 1)) * 255)
                context.setFillColor(CGColor(red: CGFloat(gray) / 255.0,
                                             green: CGFloat(1.0 - Double(y) / Double(size.height)),
                                             blue: CGFloat(gray) / 255.0,
                                             alpha: 1.0))
                context.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }
        if let image = context.makeImage() {
            route = .editor(image)
        } else {
            route = .failure
        }
    }
}
