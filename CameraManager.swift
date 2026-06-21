import AVFoundation
import Vision
import SwiftUI
import Combine

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published var faceCenterNorm: CGPoint? = nil   // 归一化坐标 (0~1)，已处理镜像和 y 翻转
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let visionQueue = DispatchQueue(label: "vision.queue")
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // 前置摄像头
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) { session.addInput(input) }
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        
        if let connection = videoOutput.connection(with: .video) {
            connection.isVideoMirrored = true
            connection.videoOrientation = .portrait
        }
        
        session.commitConfiguration()
    }
    
    func start() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                   orientation: .leftMirrored,
                                                   options: [:])
        
        let faceRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNFaceObservation],
                  !results.isEmpty else {
                DispatchQueue.main.async { self?.faceCenterNorm = nil }
                return
            }
            
            let bestFace = results.max(by: { $0.confidence < $1.confidence })!
            let box = bestFace.boundingBox
            
            // 转换为 SwiftUI 坐标系（y 翻转）
            let centerNorm = CGPoint(x: box.midX,
                                     y: 1 - box.midY)
            
            DispatchQueue.main.async {
                self.faceCenterNorm = centerNorm
            }
        }
        
        try? requestHandler.perform([faceRequest])
    }
}