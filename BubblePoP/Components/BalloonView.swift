// MARK: - BalloonView.swift
import SwiftUI

struct BalloonView: View {
    let balloon: GameBalloon
    let onTap: () -> Void
    
    @State private var floatOffset: Double = 0
    @State private var rotationAngle: Double = 0
    @State private var scale: Double = 0.1
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Shadow
                BalloonShadow()
                
                // Main balloon
                BalloonBody(balloon: balloon)
                
                // String
                BalloonString()
                
                // Points display
                PointsDisplay(balloon: balloon)
            }
        }
        .position(x: balloon.x, y: balloon.y)
        .offset(y: floatOffset)
        .rotationEffect(.degrees(rotationAngle))
        .scaleEffect(scale)
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
    
    var body: some View {
        Ellipse()
            .fill(balloonGradient)
            .frame(width: GameConstants.balloonSize.width, height: GameConstants.balloonSize.height)
            .overlay(highlight)
            .overlay(border)
    }
    
    private var balloonGradient: RadialGradient {
        RadialGradient(
            colors: [
                balloon.color.opacity(0.9),
                balloon.color.opacity(0.7),
                balloon.color.opacity(0.5)
            ],
            center: UnitPoint(x: 0.3, y: 0.2),
            startRadius: 5,
            endRadius: 45
        )
    }
    
    private var highlight: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.6), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 25, height: 35)
            .offset(x: -12, y: -15)
    }
    
    private var border: some View {
        Ellipse()
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
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
