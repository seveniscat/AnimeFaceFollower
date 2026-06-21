import SwiftUI

struct AnimeCharacterView: View {
    let lookAtScreenPoint: CGPoint?      // 屏幕坐标
    let characterCenter: CGPoint         // 动漫人物在屏幕上的中心点
    
    @State private var leftPupilOffset: CGSize = .zero
    @State private var rightPupilOffset: CGSize = .zero
    
    private let maxPupilMove: CGFloat = 14
    
    var body: some View {
        ZStack {
            // 头部（皮肤色）
            Circle()
                .fill(Color(red: 1.0, green: 0.88, blue: 0.82))
                .frame(width: 160, height: 180)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            
            // 简单刘海 / 头发
            Circle()
                .fill(Color(red: 0.3, green: 0.2, blue: 0.35))
                .frame(width: 170, height: 120)
                .offset(y: -55)
            
            // 左眼
            EyeView(pupilOffset: leftPupilOffset)
                .offset(x: -32, y: -8)
            
            // 右眼
            EyeView(pupilOffset: rightPupilOffset)
                .offset(x: 32, y: -8)
            
            // 小嘴（可爱微笑）
            Capsule()
                .fill(Color(red: 0.9, green: 0.4, blue: 0.5))
                .frame(width: 28, height: 8)
                .offset(y: 45)
                .rotationEffect(.degrees(8))
            
            // 腮红
            Circle()
                .fill(Color.pink.opacity(0.25))
                .frame(width: 22, height: 14)
                .offset(x: -45, y: 18)
            Circle()
                .fill(Color.pink.opacity(0.25))
                .frame(width: 22, height: 14)
                .offset(x: 45, y: 18)
        }
        .frame(width: 180, height: 200)
        .onChange(of: lookAtScreenPoint) { newValue in
            updatePupils(lookAt: newValue)
        }
    }
    
    private func updatePupils(lookAt: CGPoint?) {
        guard let lookAt = lookAt else {
            withAnimation(.easeOut(duration: 0.2)) {
                leftPupilOffset = .zero
                rightPupilOffset = .zero
            }
            return
        }
        
        let leftEyeScreen = CGPoint(x: characterCenter.x - 32, y: characterCenter.y - 8)
        let rightEyeScreen = CGPoint(x: characterCenter.x + 32, y: characterCenter.y - 8)
        
        leftPupilOffset = calculatePupilOffset(from: leftEyeScreen, to: lookAt)
        rightPupilOffset = calculatePupilOffset(from: rightEyeScreen, to: lookAt)
    }
    
    private func calculatePupilOffset(from eyeCenter: CGPoint, to target: CGPoint) -> CGSize {
        let dx = target.x - eyeCenter.x
        let dy = target.y - eyeCenter.y
        let dist = sqrt(dx*dx + dy*dy)
        
        guard dist > 5 else { return .zero }
        
        let scale = min(maxPupilMove, dist) / dist
        return CGSize(width: dx * scale * 0.95,
                      height: dy * scale * 0.9)
    }
}

struct EyeView: View {
    let pupilOffset: CGSize
    
    var body: some View {
        ZStack {
            // 眼白
            Ellipse()
                .fill(Color.white)
                .frame(width: 38, height: 48)
                .overlay(
                    Ellipse()
                        .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
                )
            
            // 瞳孔
            Circle()
                .fill(Color.black)
                .frame(width: 16, height: 20)
                .offset(pupilOffset)
            
            // 高光
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 6, height: 8)
                .offset(x: -4 + pupilOffset.width * 0.3,
                        y: -6 + pupilOffset.height * 0.3)
        }
    }
}