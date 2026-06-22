import SwiftUI

// Enhanced Anime Character with better visuals and blink animation
struct AnimeCharacterView: View {
    let lookAtScreenPoint: CGPoint?
    let characterCenter: CGPoint
    let faceSize: CGFloat? = nil
    
    @State private var pupilOffset: CGSize = .zero
    @State private var isBlinking: Bool = false

    // 双眼瞳孔共享同一个偏移，保证两眼同步、对称
    private let maxPupilMove: CGFloat = 22       // 放大眼睛后，瞳孔最大移动距离
    private let deadZone: CGFloat = 60           // 中心死区半径（屏幕 pt）：目标在附近时回中
    
    var body: some View {
        ZStack {
            // Shoulders/Neck
            RoundedRectangle(cornerRadius: 40)
                .fill(Color(red: 0.98, green: 0.84, blue: 0.78))
                .frame(width: 125, height: 85)
                .offset(y: 98)
            
            // Clothing
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(red: 0.45, green: 0.25, blue: 0.65))
                .frame(width: 145, height: 95)
                .offset(y: 130)
            
            // Head
            Circle()
                .fill(Color(red: 1.0, green: 0.87, blue: 0.81))
                .frame(width: 172, height: 190)
                .shadow(radius: 12, y: 8)
            
            // Hair - layered for volume
            Group {
                Circle()
                    .fill(Color(red: 0.22, green: 0.12, blue: 0.38))
                    .frame(width: 182, height: 142)
                    .offset(y: -52)
                Ellipse()
                    .fill(Color(red: 0.18, green: 0.08, blue: 0.32))
                    .frame(width: 138, height: 78)
                    .offset(y: -78)
            }
            
            // Eyebrows（间距与位置适配放大的眼睛）
            HStack(spacing: 52) {
                Eyebrow()
                Eyebrow().rotationEffect(.degrees(8))
            }
            .offset(y: -52)
            
            // Eyes（放大并加宽间距）
            HStack(spacing: 42) {
                EyeView(pupilOffset: pupilOffset, isBlinking: isBlinking)
                EyeView(pupilOffset: pupilOffset, isBlinking: isBlinking)
            }
            .offset(y: -10)
            
            // Mouth
            MouthView()
                .offset(y: 52)
            
            // Blush（位置避开放大的眼睛）
            HStack(spacing: 70) {
                Circle().fill(Color.pink.opacity(0.28)).frame(width: 32)
                Circle().fill(Color.pink.opacity(0.28)).frame(width: 32)
            }
            .offset(y: 30)
        }
        .frame(width: 220, height: 280)
        .onChange(of: lookAtScreenPoint) { updatePupils($0) }
        .onAppear(perform: startBlinking)
    }
    
    private func updatePupils(_ lookAt: CGPoint?) {
        guard let lookAt = lookAt else {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.68)) {
                pupilOffset = .zero
            }
            return
        }

        // 用双眼中点作为“视线起点”，两只眼睛共享同一偏移量 → 同步且对称
        let eyeMid = CGPoint(x: characterCenter.x, y: characterCenter.y - 12)
        let newOffset = calculateOffset(from: eyeMid, to: lookAt)

        withAnimation(.spring(response: 0.16, dampingFraction: 0.72)) {
            pupilOffset = newOffset
        }
    }

    /// 计算视线偏移：单位方向 × 距离映射，并在中心死区内归零
    private func calculateOffset(from eye: CGPoint, to target: CGPoint) -> CGSize {
        let dx = target.x - eye.x
        let dy = target.y - eye.y
        let dist = sqrt(dx*dx + dy*dy)

        // 中心死区：目标足够近时，瞳孔回到正中
        guard dist > deadZone else { return .zero }

        // 死区外按 (dist - deadZone) 线性映射，并在达到 maxPupilMove 后封顶
        let magnitude = min(maxPupilMove, (dist - deadZone) * 0.18)
        let scale = magnitude / dist
        return CGSize(width: dx * scale, height: dy * scale)
    }
    
    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3.2...7.5), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) { isBlinking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                withAnimation { isBlinking = false }
            }
        }
    }
}

// Subviews (EyeView, Eyebrow, MouthView) defined here... (full implementation in repo)

// MARK: - Subviews

struct EyeView: View {
    let pupilOffset: CGSize
    let isBlinking: Bool

    var body: some View {
        ZStack {
            // 白眼球（放大）
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .frame(width: 64, height: 78)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color(red: 0.22, green: 0.12, blue: 0.38), lineWidth: 2.5)
                )

            // 瞳孔（仅在非眨眼时显示，同步放大）
            if !isBlinking {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.32, green: 0.55, blue: 0.92))
                        .frame(width: 38, height: 38)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 13, height: 13)
                        .offset(x: -7, y: -7)
                }
                .offset(pupilOffset)
            } else {
                // 眨眼时的眼皮线
                Capsule()
                    .fill(Color(red: 0.22, green: 0.12, blue: 0.38))
                    .frame(width: 56, height: 6)
            }
        }
        .frame(width: 64, height: 78)
    }
}

struct Eyebrow: View {
    var body: some View {
        Capsule()
            .fill(Color(red: 0.18, green: 0.08, blue: 0.32))
            .frame(width: 34, height: 7)
    }
}

struct MouthView: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addQuadCurve(to: CGPoint(x: 24, y: 0),
                              control: CGPoint(x: 12, y: 14))
        }
        .stroke(Color(red: 0.55, green: 0.18, blue: 0.28),
                style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .frame(width: 24, height: 14)
    }
}
