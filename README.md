# Threshold

Threshold is a monochrome iOS photo tool built with SwiftUI for iOS 26. It launches directly into camera capture, lets you threshold to black and white, perform hard-edged brush touch-ups, and export a 4:5 portrait PNG sized for Instagram.

## Features
- Immediate camera presentation with concise permission handling and a retry path.
- Center-crop to 4:5 portrait then scale to a 2000×2500 working canvas (portrait 5:4 with height larger than width).
- Photoshop-style threshold slider (1–255, default 128) with live preview.
- Hard-edged black/white brush with continuous slider and S/M/L quick picks, plus undo/redo/reset.
- Export/share as a deterministic PNG at 2000×2500 pixels; share sheet allows saving to Photos.
- UI test-friendly debug path that loads a bundled sample image when `UITESTING=1` is set.

## Build & Run
1. Open `Threshold.xcodeproj` in Xcode 16+.
2. Select the **Threshold** target and run on an iOS 26 simulator or device.
3. The app requests camera access immediately and opens the capture view.

## Permissions
- **Camera** (`NSCameraUsageDescription`): required to capture a photo for editing.
- If permission is denied or restricted, a monochrome rationale screen offers a deep-link to Settings.

## Architecture
- **SwiftUI lifecycle** with an `AppCoordinator` controlling routes.
- **Camera**: `CameraService` (AVFoundation) + `CameraCaptureView` for preview and capture.
- **Editor**: `EditorViewModel` drives state; `ImageProcessor` performs crop, scale, grayscale + threshold, compositing with `BrushMask` overrides and `BrushRenderer` strokes.
- **Utilities**: haptics helpers, aspect-fit geometry helpers, share sheet wrapper.
- **Resources**: monochrome App Icon and a small bundled sample image for UI tests.

## Imaging Pipeline
1. Capture image → center crop to 4:5 portrait → scale to 2000×2500 working size (5:4 portrait canvas noted as 2500×2000 in requirements; this implementation uses width 2000 / height 2500 to preserve portrait orientation).
2. Convert to device gray; apply threshold (`>= value` becomes white, else black).
3. Maintain a brush override mask (neutral/black/white). Strokes rasterize hard-edged circles along the drag path.
4. Composite mask over the thresholded buffer, render to `CGImage` for display, and export PNG from the merged buffer.

## Testing
- **Unit tests** (`ThresholdTests`):
  - Crop math produces a centered 4:5 portrait crop for arbitrary input sizes.
  - Thresholding on tiny grayscale buffers yields exact black/white outputs for chosen thresholds.
  - Brush overrides replace pixels in the target region deterministically.
- **UI test** (`ThresholdUITests`): sets `UITESTING=1`, launches into the editor with the bundled sample image, and asserts core controls exist (threshold slider, brush controls, share button).

## Extending
- Adjust `targetSize` in `ImageProcessor` to support additional export sizes or aspect ratios.
- Add alternative filters by introducing new buffers and switching the compositor input.
- Expand brush features (e.g., shape presets) by extending `BrushRenderer` and adding new controls.
