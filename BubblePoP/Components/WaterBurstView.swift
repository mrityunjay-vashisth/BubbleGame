import SwiftUI

struct WaterBurstView: View {
    let position: CGPoint
    let color: Color
    @State private var particles: [WaterParticle] = []
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                WaterDroplet(particle: particle, baseColor: color)
            }
            
            SplashRing(color: color)
        }
        .position(position)
        .opacity(opacity)
        .onAppear {
            createBurst()
            fadeOut()
        }
    }
    
    private func createBurst() {
        particles = (0..<25).map { _ in
            WaterParticle(
                id: UUID(),
                offset: .zero,
                velocity: CGPoint(
                    x: Double.random(in: -150...150),
                    y: Double.random(in: -200...50)
                ),
                size: Double.random(in: 4...12),
                rotation: Double.random(in: 0...360)
            )
        }
    }
    
    private func fadeOut() {
        withAnimation(.easeOut(duration: 1.2)) {
            opacity = 0
        }
    }
}

struct WaterParticle: Identifiable {
    let id: UUID
    var offset: CGPoint
    var velocity: CGPoint
    let size: Double
    let rotation: Double
}

struct WaterDroplet: View {
    let particle: WaterParticle
    let baseColor: Color
    @State private var offset = CGPoint.zero
    @State private var opacity: Double = 1.0
    @State private var scale: Double = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            baseColor.opacity(0.8),
                            baseColor.opacity(0.4),
                            Color.white.opacity(0.3)
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 1,
                        endRadius: 5
                    )
                )
            
            Circle()
                .fill(Color.white.opacity(0.6))
                .scaleEffect(0.3)
                .offset(x: -particle.size * 0.2, y: -particle.size * 0.2)
        }
        .frame(width: particle.size, height: particle.size)
        .rotationEffect(.degrees(particle.rotation))
        .offset(x: offset.x, y: offset.y)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            animateDroplet()
        }
    }
    
    private func animateDroplet() {
        withAnimation(.interpolatingSpring(stiffness: 50, damping: 5)) {
            offset = CGPoint(
                x: particle.velocity.x,
                y: particle.velocity.y
            )
        }
        
        withAnimation(.easeIn(duration: 0.8)) {
            offset.y += 300
            scale = 0.3
            opacity = 0
        }
    }
}

struct SplashRing: View {
    let color: Color
    @State private var scale: Double = 0.5
    @State private var opacity: Double = 0.8
    
    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        color.opacity(0.6),
                        Color.white.opacity(0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 3
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .blur(radius: 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    scale = 3.0
                    opacity = 0
                }
            }
    }
}