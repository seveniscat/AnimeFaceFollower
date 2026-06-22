import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                // 动漫人物（屏幕居中）
                let charCenter = CGPoint(
                    x: geometry.size.width * 0.5,
                    y: geometry.size.height * 0.5
                )

                let lookAtPoint: CGPoint? = cameraManager.faceCenterNorm.map { norm in
                    CGPoint(x: norm.x * geometry.size.width,
                            y: norm.y * geometry.size.height)
                }

                AnimeCharacterView(lookAtScreenPoint: lookAtPoint,
                                   characterCenter: charCenter)
                    .position(charCenter)

                // 顶部提示
                VStack {
                    Text("让我的眼睛跟着你～")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.6))
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(.top, 60)

                // 调试预览（仅 DEBUG 构建包含）
                #if DEBUG
                DebugPreview(
                    session: cameraManager.session,
                    faceBoxNorm: cameraManager.faceBoxNorm,
                    faceCenterNorm: cameraManager.faceCenterNorm
                )
                .frame(width: 180, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(radius: 6)
                .position(x: geometry.size.width - 100, y: 140)
                #endif
            }
        }
        .onAppear {
            cameraManager.start()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }
}

#if DEBUG
/// 调试用预览：相机画面 + Vision 检测到的人脸框 + 中心十字 + 数值标签
struct DebugPreview: View {
    let session: AVCaptureSession
    let faceBoxNorm: CGRect?
    let faceCenterNorm: CGPoint?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 相机画面（与全屏预览一致的镜像呈现）
                CameraPreview(session: session)

                // 人脸框
                if let box = faceBoxNorm {
                    Rectangle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: box.width * geo.size.width,
                               height: box.height * geo.size.height)
                        .position(x: (box.origin.x + box.width / 2) * geo.size.width,
                                  y: (box.origin.y + box.height / 2) * geo.size.height)
                }

                // 人脸中心十字
                if let c = faceCenterNorm {
                    ZStack {
                        Rectangle().fill(Color.red).frame(width: 2, height: 14)
                        Rectangle().fill(Color.red).frame(width: 14, height: 2)
                    }
                    .position(x: c.x * geo.size.width, y: c.y * geo.size.height)
                }

                // 角标：显示归一化坐标
                VStack(alignment: .leading, spacing: 2) {
                    if let c = faceCenterNorm {
                        Text(String(format: "x %.2f", c.x))
                            .font(.system(size: 9, design: .monospaced))
                        Text(String(format: "y %.2f", c.y))
                            .font(.system(size: 9, design: .monospaced))
                    } else {
                        Text("no face")
                            .font(.system(size: 9))
                    }
                }
                .foregroundStyle(.yellow)
                .padding(4)
                .background(.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
#endif

#Preview {
    ContentView()
}
