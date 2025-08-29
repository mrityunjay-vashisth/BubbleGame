// MARK: - BalloonView.swift
import SwiftUI

struct BalloonView: View {
    let balloon: GameBalloon
    let onTap: () -> Void
    
    @State private var scale: Double = 0.1
    @State private var floatOffset: Double = 0
    
    // Pre-computed sizing for better performance
    private var sizeMultiplier: Double {
        // Use lookup table for common point values to avoid repeated calculations
        switch balloon.points {
        case 1: return 0.5
        case 2: return 0.7
        case 3: return 0.9
        case 4: return 1.1
        case 5: return 1.3
        default: return max(0.4, 0.3 + (Double(balloon.points) * 0.2))
        }
    }
    
    // Cache computed values to avoid repeated calculations
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
        .position(x: balloon.x, y: balloon.y + floatOffset)
        .scaleEffect(scale)
        .onTapGesture {
            onTap()
        }
        .onAppear {
            setupAnimations()
        }
    }
    
    private func setupAnimations() {
        // Quick, snappy spawn animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            scale = 1.0
        }
        
        // Simple floating animation - no complex math
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            floatOffset = Double.random(in: -5...5)
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
            .blur(radius: 2)
    }
}

struct BalloonBody: View {
    let balloon: GameBalloon
    let width: Double
    let height: Double
    @State private var waterWobble: Double = 0
    
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
                .offset(y: waterWobble)
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
        .onAppear {
            // Simple water wobble effect
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                waterWobble = 3.0
            }
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
                .shadow(color: .black.opacity(0.5), radius: 1)
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