import AVFoundation
import UIKit

enum CameraAuthorizationStatus {
    case authorized
    case denied
    case restricted
    case notDetermined
}

enum CameraError: Error {
    case configurationFailed
    case captureFailed
}

final class CameraService: NSObject, AVCapturePhotoCaptureDelegate {
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let output = AVCapturePhotoOutput()
    private var captureContinuation: CheckedContinuation<Result<CGImage, Error>, Never>?

    func checkAuthorization() async -> CameraAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .restricted
        }
    }

    func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    func makeSession() throws -> AVCaptureSession {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { throw CameraError.configurationFailed }
        session.addInput(input)
        guard session.canAddOutput(output) else { throw CameraError.configurationFailed }
        session.addOutput(output)
        output.isHighResolutionCaptureEnabled = true
        session.commitConfiguration()
        return session
    }

    func start(session: AVCaptureSession) {
        sessionQueue.async {
            if !session.isRunning {
                session.startRunning()
            }
        }
    }

    func capturePhoto() async -> Result<CGImage, Error> {
        await withCheckedContinuation { continuation in
            captureContinuation = continuation
            let settings = AVCapturePhotoSettings()
            settings.isHighResolutionPhotoEnabled = true
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            captureContinuation?.resume(returning: .failure(error))
            captureContinuation = nil
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: data),
              let cgImage = uiImage.cgImage else {
            captureContinuation?.resume(returning: .failure(CameraError.captureFailed))
            captureContinuation = nil
            return
        }
        captureContinuation?.resume(returning: .success(cgImage))
        captureContinuation = nil
    }
}
