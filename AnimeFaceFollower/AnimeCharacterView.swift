import SwiftUI

// Enhanced Anime Character with better visuals and blink animation
struct AnimeCharacterView: View {
    let lookAtScreenPoint: CGPoint?
    let characterCenter: CGPoint
    let faceSize: CGFloat? = nil
    
    @State private var leftPupilOffset: CGSize = .zero
    @State private var rightPupilOffset: CGSize = .zero
    @State private var isBlinking: Bool = false
    
    private let maxPupilMove: CGFloat = 13.5
    
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
            
            // Eyebrows
            HStack(spacing: 26) {
                Eyebrow()
                Eyebrow().rotationEffect(.degrees(8))
            }
            .offset(y: -26)
            
            // Eyes
            HStack(spacing: 32) {
                EyeView(pupilOffset: leftPupilOffset, isBlinking: isBlinking)
                EyeView(pupilOffset: rightPupilOffset, isBlinking: isBlinking)
            }
            .offset(y: -10)
            
            // Mouth
            MouthView()
                .offset(y: 52)
            
            // Blush
            HStack(spacing: 48) {
                Circle().fill(Color.pink.opacity(0.28)).frame(width: 28)
                Circle().fill(Color.pink.opacity(0.28)).frame(width: 28)
            }
            .offset(y: 24)
        }
        .frame(width: 200, height: 260)
        .onChange(of: lookAtScreenPoint) { updatePupils($0) }
        .onAppear(perform: startBlinking)
    }
    
    private func updatePupils(_ lookAt: CGPoint?) {
        guard let lookAt = lookAt else {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.68)) {
                leftPupilOffset = .zero
                rightPupilOffset = .zero
            }
            return
        }
        
        let leftEye = CGPoint(x: characterCenter.x - 34, y: characterCenter.y - 12)
        let rightEye = CGPoint(x: characterCenter.x + 34, y: characterCenter.y - 12)
        
        let newLeft = calculateOffset(from: leftEye, to: lookAt)
        let newRight = calculateOffset(from: rightEye, to: lookAt)
        
        withAnimation(.spring(response: 0.16, dampingFraction: 0.72)) {
            leftPupilOffset = newLeft
            rightPupilOffset = newRight
        }
    }
    
    private func calculateOffset(from eye: CGPoint, to target: CGPoint) -> CGSize {
        let dx = target.x - eye.x
        let dy = target.y - eye.y
        let dist = sqrt(dx*dx + dy*dy)
        guard dist > 10 else { return .zero }
        let scale = min(maxPupilMove, dist * 0.55) / dist
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
            // 白眼球
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: 44, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.22, green: 0.12, blue: 0.38), lineWidth: 2)
                )

            // 瞳孔（仅在非眨眼时显示）
            if !isBlinking {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.32, green: 0.55, blue: 0.92))
                        .frame(width: 26, height: 26)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 9, height: 9)
                        .offset(x: -5, y: -5)
                }
                .offset(pupilOffset)
            } else {
                // 眨眼时的眼皮线
                Capsule()
                    .fill(Color(red: 0.22, green: 0.12, blue: 0.38))
                    .frame(width: 38, height: 5)
            }
        }
        .frame(width: 44, height: 54)
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
