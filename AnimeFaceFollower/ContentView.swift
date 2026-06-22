import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 摄像头预览（全屏）
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()
                
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