import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer)

        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // 兜底；真正的 frame 同步在 PreviewView.layoutSubviews() 里做
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }

    /// 自定义 UIView：每次布局时把 bounds 同步给 previewLayer，
    /// 解决 SwiftUI 小窗里 bounds 在 makeUIView 阶段为 .zero 导致相机画面不显示的问题。
    final class PreviewView: UIView {
        override func layoutSubviews() {
            super.layoutSubviews()
            guard let sublayers = layer.sublayers else { return }
            for case let sub as AVCaptureVideoPreviewLayer in sublayers {
                sub.frame = bounds
            }
        }
    }
}
