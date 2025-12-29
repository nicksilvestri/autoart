import SwiftUI

struct RootView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        Group {
            switch coordinator.route {
            case .camera:
                CameraCaptureView()
            case .editor(let image):
                EditorContainerView(sourceImage: image, onReset: coordinator.resetToCamera)
            case .permissionDenied:
                PermissionView()
            case .failure:
                FailureView(retry: coordinator.resetToCamera)
            }
        }
        .background(Color.black)
        .onAppear {
            coordinator.start()
        }
    }
}

private struct PermissionView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Camera access is required.")
                .font(.title2)
                .foregroundStyle(.white)
            Button(action: openSettings) {
                Text("Open Settings")
                    .foregroundStyle(.black)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding()
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private struct FailureView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Camera unavailable")
                .foregroundStyle(.white)
            Button("Retry Camera", action: retry)
                .padding()
                .foregroundStyle(.black)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding()
    }
}
