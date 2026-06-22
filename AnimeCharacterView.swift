import SwiftUI

struct AnimeCharacterView: View {
    let lookAtScreenPoint: CGPoint?
    let characterCenter: CGPoint
    let faceSize: CGFloat?  // 用于根据人脸大小调整角色表情/大小
    
    @State private var leftPupilOffset: CGSize = .zero
    @State private var rightPupilOffset: CGSize = .zero
    @State private var isBlinking: Bool = false
    
    private let maxPupilMove: CGFloat = 13
    
    var body: some View {
        ZStack {
            // 脖子/肩膀
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(red: 1.0, green: 0.85, blue: 0.78))
                .frame(width: 110, height: 80)
                .offset(y: 95)
            
            // 衣服
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.purple.opacity(0.9))
                .frame(width: 130, height: 90)
                .offset(y: 125)
            
            // 头部
            Circle()
                .fill(Color(red: 1.0, green: 0.88, blue: 0.82))
                .frame(width: 165, height: 185)
                .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
            
            // 头发（分层，更有体积感）
            Group {
                Circle()
                    .fill(Color(red: 0.25, green: 0.15, blue: 0.4))
                    .frame(width: 175, height: 135)
                    .offset(y: -48)
                // 刘海
                Ellipse()
                    .fill(Color(red: 0.2, green: 0.1, blue: 0.35))
                    .frame(width: 130, height: 70)
                    .offset(y: -72)
            }
            
            // 眉毛
            Group {
                Eyebrow(isLeft: true)
                    .offset(x: -35, y: -25)
                Eyebrow(isLeft: false)
                    .offset(x: 35, y: -25)
            }
            
            // 眼睛容器
            HStack(spacing: 28) {
                EyeView(pupilOffset: leftPupilOffset, isBlinking: isBlinking)
                EyeView(pupilOffset: rightPupilOffset, isBlinking: isBlinking)
            }
            .offset(y: -12)
            
            // 嘴巴
            MouthView(isSmiling: true)
                .offset(y: 48)
            
            // 腮红
            HStack(spacing: 50) {
                Circle().fill(Color.pink.opacity(0.3)).frame(width: 26, height: 16)
                Circle().fill(Color.pink.opacity(0.3)).frame(width: 26, height: 16)
            }
            .offset(y: 22)
        }
        .frame(width: 190, height: 240)
        .scaleEffect(faceSize != nil ? min(1.1, 0.8 + (faceSize! / 300)) : 1.0)
        .onChange(of: lookAtScreenPoint) { newValue in
            updatePupils(lookAt: newValue)
        }
        .onAppear {
            startBlinking()
        }
    }
    
    private func updatePupils(lookAt: CGPoint?) {
        // ... (保持之前的计算逻辑，增加平滑)
        // 可以在这里加简单低通滤波
        guard let lookAt = lookAt else {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                leftPupilOffset = .zero
                rightPupilOffset = .zero
            }
            return
        }
        
        let leftEye = CGPoint(x: characterCenter.x - 32, y: characterCenter.y - 12)
        let rightEye = CGPoint(x: characterCenter.x + 32, y: characterCenter.y - 12)
        
        let newLeft = calculatePupilOffset(from: leftEye, to: lookAt)
        let newRight = calculatePupilOffset(from: rightEye, to: lookAt)
        
        withAnimation(.spring(response: 0.18, dampingFraction: 0.75)) {
            leftPupilOffset = newLeft
            rightPupilOffset = newRight
        }
    }
    
    private func calculatePupilOffset(from eyeCenter: CGPoint, to target: CGPoint) -> CGSize {
        let dx = target.x - eyeCenter.x
        let dy = target.y - eyeCenter.y
        let dist = sqrt(dx*dx + dy*dy)
        guard dist > 8 else { return .zero }
        let scale = min(maxPupilMove, dist * 0.6) / dist
        return CGSize(width: dx * scale, height: dy * scale)
    }
    
    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3.5...8.0), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.12)) {
                isBlinking = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.1)) {
                    isBlinking = false
                }
            }
        }
    }
}

// 其他子视图 (EyeView, Eyebrow, MouthView) 保持或略微升级
struct EyeView: View {
    let pupilOffset: CGSize
    let isBlinking: Bool
    
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.white)
                .frame(width: 42, height: 50)
            
            if !isBlinking {
                Circle()
                    .fill(Color.black)
                    .frame(width: 17, height: 22)
                    .offset(pupilOffset)
                
                Circle()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: 7, height: 9)
                    .offset(x: pupilOffset.width - 5, y: pupilOffset.height - 7)
            } else {
                // 闭眼状态
                Rectangle()
                    .fill(Color(red: 0.95, green: 0.75, blue: 0.7))
                    .frame(width: 42, height: 12)
            }
        }
    }
}

struct Eyebrow: View {
    let isLeft: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.black.opacity(0.7))
            .frame(width: 32, height: 6)
            .rotationEffect(.degrees(isLeft ? -12 : 12))
    }
}

struct MouthView: View {
    let isSmiling: Bool
    var body: some View {
        Capsule()
            .fill(Color(red: 0.85, green: 0.35, blue: 0.45))
            .frame(width: 32, height: 10)
            .offset(y: isSmiling ? 0 : 2)
    }
}