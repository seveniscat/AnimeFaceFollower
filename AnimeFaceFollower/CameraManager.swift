import AVFoundation
import Combine
import UIKit
import Vision

class CameraManager: NSObject, ObservableObject {
    @Published var faceCenterNorm: CGPoint? = nil
    #if DEBUG
    /// 调试用：最新人脸框（已转换到屏幕坐标系，归一化 0~1，原点左上）
    @Published var faceBoxNorm: CGRect? = nil
    #endif

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let visionQueue = DispatchQueue(label: "camera.vision.queue")

    private var detectionInterval: Int = 0
    private var lastObservation: VNFaceObservation?

    override init() {
        super.init()
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureSession()
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: visionQueue)
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.connection(with: .video)?.videoOrientation = .portrait
        }

        session.commitConfiguration()
    }

    private func handleFaces(_ observations: [VNFaceObservation], for buffer: CVPixelBuffer) {
        guard let observation = observations.max(by: { $0.boundingBox.width < $1.boundingBox.width }) else {
            DispatchQueue.main.async {
                self.faceCenterNorm = nil
                #if DEBUG
                self.faceBoxNorm = nil
                #endif
            }
            return
        }

        let box = observation.boundingBox
        // x：前置预览已镜像，boundingBox.x 与屏幕方向一致，无需翻转
        // y：Vision 坐标原点在左下、屏幕原点在左上，需做 1 - y 翻转
        let center = CGPoint(x: box.origin.x + box.width / 2,
                             y: 1 - (box.origin.y + box.height / 2))
        #if DEBUG
        let screenBox = CGRect(x: box.origin.x,
                               y: 1 - box.origin.y - box.height,
                               width: box.width,
                               height: box.height)
        DispatchQueue.main.async {
            self.faceCenterNorm = center
            self.faceBoxNorm = screenBox
        }
        #else
        DispatchQueue.main.async { self.faceCenterNorm = center }
        #endif
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        detectionInterval += 1

        // 每 2 帧进行一次完整检测，其余帧尝试用上次观测做跟踪
        if detectionInterval % 2 == 0 || lastObservation == nil {
            let request = VNDetectFaceRectanglesRequest { [weak self] request, _ in
                guard let self = self,
                      let results = request.results as? [VNFaceObservation],
                      let first = results.first else { return }
                self.lastObservation = first
                self.handleFaces(results, for: pixelBuffer)
            }
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored)
            try? handler.perform([request])
        } else if let last = lastObservation {
            // 轻量跟踪请求：复用上一次的 bounding box
            let track = VNTrackObjectRequest(detectedObjectObservation: last) { [weak self] request, _ in
                guard let self = self,
                      let result = request.results?.first as? VNFaceObservation else {
                    self?.lastObservation = nil
                    return
                }
                self.lastObservation = result
                self.handleFaces([result], for: pixelBuffer)
            }
            track.trackingLevel = VNRequestTrackingLevel.fast
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored)
            try? handler.perform([track])
        }
    }
}
