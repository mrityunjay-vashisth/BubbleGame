// MARK: - BalloonView.swift
import SwiftUI

struct BalloonView: View {
    let balloon: GameBalloon
    let onTap: () -> Void
    
    @State private var floatOffset: Double = 0
    @State private var rotationAngle: Double = 0
    @State private var scale: Double = 0.1
    @State private var waterWobble: Double = 0
    
    // Dynamic sizing based on points
    private var sizeMultiplier: Double {
        let absPoints = Double(balloon.points) // points is already absolute value
        // EXTREME scaling to make size differences impossible to miss
        // 1 point = 0.5x (tiny), 2 points = 0.7x (small), 5 points = 1.3x (big), 10 points = 2.3x (huge!)
        let multiplier = 0.3 + (absPoints * 0.2) // VERY aggressive scaling
        print("   🔍 Points: \(balloon.points) → Multiplier: \(String(format: "%.2f", multiplier)) → Final size: \(String(format: "%.0f", GameConstants.balloonSize.width * multiplier))")
        return max(0.4, multiplier)
    }
    
    private var balloonWidth: Double {
        GameConstants.balloonSize.width * sizeMultiplier
    }
    
    private var balloonHeight: Double {
        GameConstants.balloonSize.height * sizeMultiplier
    }
    
    var body: some View {
        ZStack {
            // Shadow (scaled with balloon)
            BalloonShadow(width: balloonWidth * 1.1, height: balloonHeight * 1.1)
            
            // Main balloon with water effect
            BalloonBody(
                balloon: balloon,
                wobble: waterWobble,
                width: balloonWidth,
                height: balloonHeight
            )
            
            // String (length scales with balloon size)
            BalloonString(height: 25 * sizeMultiplier)
            
            // Points display (scales with balloon)
            PointsDisplay(
                balloon: balloon,
                fontSize: 12 + (6 * sizeMultiplier)
            )
        }
        .frame(width: balloonWidth * 1.3, height: balloonHeight * 1.3)
        .contentShape(
            Ellipse()
                .size(
                    width: balloonWidth * 1.3,
                    height: balloonHeight * 1.3
                )
        )
        .position(x: balloon.x, y: balloon.y)
        .offset(y: floatOffset)
        .rotationEffect(.degrees(rotationAngle))
        .scaleEffect(scale)
        .onTapGesture {
            onTap()
        }
        .onAppear {
            // Debug: Log detailed balloon sizing info
            print("🎈 Balloon: \(balloon.points)pts → multiplier: \(String(format: "%.2f", sizeMultiplier)) → size: \(String(format: "%.0f", balloonWidth))x\(String(format: "%.0f", balloonHeight))")
            print("   Base size: \(GameConstants.balloonSize.width)x\(GameConstants.balloonSize.height)")
            setupAnimations()
        }
    }
    
    private func setupAnimations() {
        // Spawn animation
        withAnimation(.spring(duration: GameConstants.balloonSpawnDuration, bounce: 0.4)) {
            scale = 1.0
        }
        
        // Float animation (larger balloons float less)
        let floatRange = 15.0 / sizeMultiplier
        floatOffset = Double.random(in: -floatRange...floatRange)
        
        // Rotation animation (larger balloons rotate less)
        let rotationRange = 20.0 / sizeMultiplier
        rotationAngle = Double.random(in: -rotationRange...rotationRange)
        
        // Start float cycle (slower for bigger balloons)
        let floatDuration = 2.0 + (sizeMultiplier * 1.5)
        withAnimation(.easeInOut(duration: floatDuration).repeatForever(autoreverses: true)) {
            floatOffset = -floatOffset
        }
        
        // Start rotation cycle
        let rotationDuration = 4.0 + (sizeMultiplier * 2.0)
        withAnimation(.easeInOut(duration: rotationDuration).repeatForever(autoreverses: true)) {
            rotationAngle = -rotationAngle
        }
        
        // Water wobble animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            waterWobble = 5 / sizeMultiplier
        }
    }
}

struct BalloonShadow: View {
    let width: Double
    let height: Double
    
    var body: some View {
        Ellipse()
            .fill(Color.black.opacity(0.2))
            .frame(width: width, height: height)
            .offset(x: 3, y: 5)
            .blur(radius: 4)
    }
}

struct BalloonBody: View {
    let balloon: GameBalloon
    let wobble: Double
    let width: Double
    let height: Double
    
    var body: some View {
        ZStack {
            // Water-filled balloon with gradient
            Ellipse()
                .fill(waterGradient)
                .frame(width: width, height: height)
            
            // Water surface inside with wobble effect
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            balloon.color.opacity(0.3),
                            balloon.color.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width - 10, height: height - 10)
                .offset(y: wobble)
                .mask(
                    Ellipse()
                        .frame(width: width, height: height)
                )
            
            // Glass overlay for water effect
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.8), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: width, height: height)
            
            // Highlight (scales with balloon)
            highlight
        }
    }
    
    private var waterGradient: LinearGradient {
        LinearGradient(
            colors: [
                balloon.color.opacity(0.4),
                balloon.color.opacity(0.7),
                balloon.color.opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var highlight: some View {
        ZStack {
            // Main highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.9), Color.clear],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 1,
                        endRadius: width * 0.3
                    )
                )
                .frame(width: width * 0.3, height: height * 0.3)
                .offset(x: -width * 0.25, y: -height * 0.24)
            
            // Secondary highlight
            Ellipse()
                .fill(Color.white.opacity(0.3))
                .frame(width: width * 0.12, height: height * 0.13)
                .offset(x: -width * 0.28, y: -height * 0.26)
        }
    }
}

struct BalloonString: View {
    let height: Double
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(
                LinearGradient(
                    colors: [Color.brown.opacity(0.8), Color.brown.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2, height: height)
            .offset(y: 45)
    }
}

struct PointsDisplay: View {
    let balloon: GameBalloon
    let fontSize: Double
    
    private var displaySize: Double {
        // Bigger bubble for bigger point values - make it more dramatic
        15 + (Double(balloon.points) * 1.5)
    }
    
    var body: some View {
        ZStack {
            // Background bubble
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: displaySize, height: displaySize)
            
            // Points text
            Text(balloon.isPositive ? "+\(balloon.points)" : "-\(balloon.points)")
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(pointsGradient)
                .shadow(color: .black.opacity(0.9), radius: 2)
        }
    }
    
    private var pointsGradient: LinearGradient {
        LinearGradient(
            colors: balloon.isPositive ?
                [Color.white, GameConstants.UI.success] :
                [Color.white, GameConstants.UI.danger],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}