import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct CameraCaptureView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            if let session = viewModel.session {
                CameraPreview(session: session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            captureButton
        }
        .onAppear {
            viewModel.prepare(service: coordinator.cameraService)
        }
    }

    private var captureButton: some View {
        Button(action: capture) {
            Circle()
                .strokeBorder(Color.white, lineWidth: 4)
                .frame(width: 84, height: 84)
                .padding(.bottom, 32)
        }
    }

    private func capture() {
        Haptics.tap()
        Task {
            let result = await viewModel.capture()
            coordinator.handleCapture(result: result)
        }
    }
}

@MainActor
final class CameraViewModel: ObservableObject {
    @Published var session: AVCaptureSession?
    private var service: CameraService?

    func prepare(service: CameraService) {
        guard session == nil else { return }
        self.service = service
        do {
            let session = try service.makeSession()
            self.session = session
            service.start(session: session)
        } catch {
            print("Camera prepare failed: \(error)")
        }
    }

    func capture() async -> Result<CGImage, Error> {
        guard let service else { return .failure(CameraError.captureFailed) }
        return await service.capturePhoto()
    }
}
