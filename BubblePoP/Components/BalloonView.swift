// MARK: - BalloonView.swift
import SwiftUI

struct BalloonView: View {
    let balloon: GameBalloon
    let onTap: () -> Void
    
    @State private var floatOffset: Double = 0
    @State private var rotationAngle: Double = 0
    @State private var scale: Double = 0.1
    @State private var waterWobble: Double = 0
    
    var body: some View {
        ZStack {
            // Shadow
            BalloonShadow()
            
            // Main balloon with water effect
            BalloonBody(balloon: balloon, wobble: waterWobble)
            
            // String
            BalloonString()
            
            // Points display
            PointsDisplay(balloon: balloon)
        }
        .frame(width: GameConstants.balloonSize.width * 1.2, 
               height: GameConstants.balloonSize.height * 1.2)
        .contentShape(
            Ellipse()
                .size(
                    width: GameConstants.balloonSize.width * 1.2,
                    height: GameConstants.balloonSize.height * 1.2
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
            setupAnimations()
        }
    }
    
    private func setupAnimations() {
        withAnimation(.spring(duration: GameConstants.balloonSpawnDuration, bounce: 0.4)) {
            scale = 1.0
        }
        
        floatOffset = Double.random(in: -12...12)
        rotationAngle = Double.random(in: -15...15)
        
        withAnimation(.easeInOut(duration: Double.random(in: 2.0...3.5)).repeatForever(autoreverses: true)) {
            floatOffset = -floatOffset
        }
        
        withAnimation(.easeInOut(duration: Double.random(in: 4.0...6.0)).repeatForever(autoreverses: true)) {
            rotationAngle = -rotationAngle
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            waterWobble = 5
        }
    }
}

struct BalloonShadow: View {
    var body: some View {
        Ellipse()
            .fill(Color.black.opacity(0.2))
            .frame(width: 65, height: 80)
            .offset(x: 3, y: 5)
            .blur(radius: 4)
    }
}

struct BalloonBody: View {
    let balloon: GameBalloon
    let wobble: Double
    
    var body: some View {
        ZStack {
            // Water-filled balloon
            Ellipse()
                .fill(waterGradient)
                .frame(width: GameConstants.balloonSize.width, height: GameConstants.balloonSize.height)
            
            // Water surface inside
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
                .frame(width: GameConstants.balloonSize.width - 10, height: GameConstants.balloonSize.height - 10)
                .offset(y: wobble)
                .mask(
                    Ellipse()
                        .frame(width: GameConstants.balloonSize.width, height: GameConstants.balloonSize.height)
                )
            
            // Glass overlay
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.8), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
            
            // Highlight
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
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.9), Color.clear],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 1,
                        endRadius: 20
                    )
                )
                .frame(width: 20, height: 25)
                .offset(x: -15, y: -18)
            
            Ellipse()
                .fill(Color.white.opacity(0.3))
                .frame(width: 8, height: 10)
                .offset(x: -18, y: -20)
        }
    }
    
}

struct BalloonString: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(
                LinearGradient(
                    colors: [Color.brown.opacity(0.8), Color.brown.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2, height: 30)
            .offset(y: 45)
    }
}

struct PointsDisplay: View {
    let balloon: GameBalloon
    
    var body: some View {
        Text(balloon.isPositive ? "+\(balloon.points)" : "-\(balloon.points)")
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(pointsGradient)
            .shadow(color: .black.opacity(0.9), radius: 3)
            .background(pointsBackground)
    }
    
    private var pointsGradient: LinearGradient {
        LinearGradient(
            colors: balloon.isPositive ?
                [Color.white, Color.mint] :
                [Color.white, Color.orange],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var pointsBackground: some View {
        Circle()
            .fill(Color.black.opacity(0.3))
            .frame(width: 32, height: 32)
    }
}
