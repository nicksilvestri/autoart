import SwiftUI

struct EditorContainerView: View {
    let sourceImage: CGImage
    let onReset: () -> Void
    @StateObject private var viewModel: EditorViewModel
    @State private var lastDragLocation: CGPoint?
    @State private var showShareSheet = false
    private let processor = ImageProcessor()

    init(sourceImage: CGImage, onReset: @escaping () -> Void) {
        self.sourceImage = sourceImage
        self.onReset = onReset
        if let working = processor.prepareWorkingImage(from: sourceImage) {
            _viewModel = StateObject(wrappedValue: EditorViewModel(sourceImage: working))
        } else {
            _viewModel = StateObject(wrappedValue: EditorViewModel(sourceImage: sourceImage))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            GeometryReader { geo in
                ZStack {
                    Color.black
                    if let image = viewModel.renderedImage {
                        let canvasSize = processor.targetSize.aspectFit(in: geo.size)
                        Image(decorative: image, scale: 1, orientation: .up)
                            .resizable()
                            .interpolation(.none)
                            .aspectRatio(processor.targetSize, contentMode: .fit)
                            .frame(width: canvasSize.width, height: canvasSize.height)
                            .overlay(brushOverlay(size: canvasSize))
                            .gesture(drawingGesture(in: geo.size))
                    }
                }
            }
            toolbar
                .padding(.horizontal)
                .padding(.bottom, 12)
        }
        .background(Color.black)
        .sheet(isPresented: $showShareSheet) {
            if let url = viewModel.exportImage() {
                ShareSheet(activityItems: [url]) {
                    showShareSheet = false
                }
            } else {
                Text("Unable to export")
                    .foregroundStyle(.white)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: onReset) {
                Image(systemName: "camera.fill")
                    .foregroundStyle(.white)
            }
            Spacer()
            Text("Threshold")
                .foregroundStyle(.white)
                .font(.title3).bold()
            Spacer()
           Button(action: { showShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.white)
                    .padding(8)
            }
            .accessibilityIdentifier("shareButton")
        }
        .padding()
    }

    private func brushOverlay(size: CGSize) -> some View {
        Group {
            if let point = lastDragLocation {
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    .frame(width: viewModel.brushSize, height: viewModel.brushSize)
                    .position(point)
            }
        }
    }

    private func drawingGesture(in viewSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if lastDragLocation == nil {
                    viewModel.beginStroke(at: value.location, in: viewSize)
                } else if let last = lastDragLocation {
                    viewModel.continueStroke(from: last, to: value.location, in: viewSize)
                }
                lastDragLocation = value.location
            }
            .onEnded { _ in
                lastDragLocation = nil
            }
    }

    private var toolbar: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Threshold")
                        .foregroundStyle(.white)
                        .font(.footnote)
                    Spacer()
                    Text("\(Int(viewModel.thresholdValue))")
                        .foregroundStyle(.white.opacity(0.7))
                        .font(.footnote.monospaced())
                }
                Slider(value: $viewModel.thresholdValue, in: 1...255, step: 1)
                    .tint(.white)
                    .accessibilityIdentifier("thresholdSlider")
            }
            HStack(spacing: 12) {
                brushToggle
                brushSizeControl
                undoRedo
                resetButton
            }
        }
    }

    private var brushToggle: some View {
        HStack(spacing: 8) {
            Button(action: {
                viewModel.brushMode = .black
                Haptics.tap()
            }) {
                Text("Black")
                    .foregroundStyle(viewModel.brushMode == .black ? .black : .white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(viewModel.brushMode == .black ? Color.white : Color.black.opacity(0.4))
                    .clipShape(Capsule())
            }
            Button(action: {
                viewModel.brushMode = .white
                Haptics.tap()
            }) {
                Text("White")
                    .foregroundStyle(viewModel.brushMode == .white ? .black : .white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(viewModel.brushMode == .white ? Color.white : Color.black.opacity(0.4))
                    .clipShape(Capsule())
            }
        }
    }

    private var brushSizeControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Brush Size")
                .foregroundStyle(.white)
                .font(.footnote)
            HStack(spacing: 8) {
                ForEach(EditorViewModel.BrushSize.allCases, id: \.self) { size in
                    Button("\(Int(size.rawValue))") {
                        viewModel.setBrushSize(size)
                    }
                    .padding(8)
                    .background(Color.white.opacity(viewModel.brushSize == size.rawValue ? 0.8 : 0.2))
                    .foregroundStyle(viewModel.brushSize == size.rawValue ? .black : .white)
                    .clipShape(Capsule())
                }
                Slider(value: $viewModel.brushSize, in: 2...80)
                    .frame(maxWidth: 160)
                    .tint(.white)
            }
        }
    }

    private var undoRedo: some View {
        HStack(spacing: 8) {
            Button(action: viewModel.undo) {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundStyle(.white)
            }
            Button(action: viewModel.redo) {
                Image(systemName: "arrow.uturn.forward")
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 8)
    }

    private var resetButton: some View {
        Button(action: viewModel.resetEdits) {
            Text("Reset")
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .foregroundStyle(.black)
                .background(Color.white)
                .clipShape(Capsule())
        }
        .accessibilityIdentifier("resetButton")
    }
}
