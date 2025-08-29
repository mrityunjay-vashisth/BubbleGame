import SwiftUI

// MARK: - Object Pool for WaterParticles
class WaterParticlePool {
    static let shared = WaterParticlePool()
    
    private var availableParticles: [WaterParticle] = []
    private let maxPoolSize = 50
    
    private init() {
        // Pre-warm the pool with some particles
        for _ in 0..<20 {
            availableParticles.append(WaterParticle.createEmpty())
        }
    }
    
    func borrowParticles(count: Int) -> [WaterParticle] {
        var particles: [WaterParticle] = []
        
        for _ in 0..<count {
            if let particle = availableParticles.popLast() {
                particles.append(particle)
            } else {
                // Create new particle if pool is empty
                particles.append(WaterParticle.createEmpty())
            }
        }
        
        return particles
    }
    
    func returnParticles(_ particles: [WaterParticle]) {
        for particle in particles {
            if availableParticles.count < maxPoolSize {
                // Reset particle state and return to pool
                availableParticles.append(particle.reset())
            }
        }
    }
}

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
        .onDisappear {
            // Return particles to pool when view disappears
            WaterParticlePool.shared.returnParticles(particles)
        }
    }
    
    private func createBurst() {
        // Reduce particle count based on device performance for better frame rates
        let particleCount = PerformanceDetector.shared.enableComplexAnimations ? 15 : 8
        
        // Use object pool for better memory performance
        var pooledParticles = WaterParticlePool.shared.borrowParticles(count: particleCount)
        
        // Configure each pooled particle with random values
        for i in 0..<pooledParticles.count {
            pooledParticles[i].configure(
                velocity: CGPoint(
                    x: Double.random(in: -120...120),
                    y: Double.random(in: -160...40)
                ),
                size: Double.random(in: 5...10),
                rotation: Double.random(in: 0...360)
            )
        }
        
        particles = pooledParticles
    }
    
    private func fadeOut() {
        withAnimation(.easeOut(duration: 1.2)) {
            opacity = 0
        }
    }
}

struct WaterParticle: Identifiable {
    let id: Int
    var offset: CGPoint
    var velocity: CGPoint
    var size: Double
    var rotation: Double
    
    // Static counter for efficient ID generation (much faster than UUID)
    private static var nextID: Int = 0
    
    static func create(velocity: CGPoint, size: Double, rotation: Double) -> WaterParticle {
        nextID += 1
        return WaterParticle(
            id: nextID,
            offset: .zero,
            velocity: velocity,
            size: size,
            rotation: rotation
        )
    }
    
    static func createEmpty() -> WaterParticle {
        nextID += 1
        return WaterParticle(
            id: nextID,
            offset: .zero,
            velocity: .zero,
            size: 0,
            rotation: 0
        )
    }
    
    // Reset particle for reuse in object pool
    func reset() -> WaterParticle {
        return WaterParticle(
            id: self.id,
            offset: .zero,
            velocity: .zero,
            size: 0,
            rotation: 0
        )
    }
    
    // Configure particle with new values (for pooled objects)
    mutating func configure(velocity: CGPoint, size: Double, rotation: Double) {
        self.offset = .zero
        self.velocity = velocity
        self.size = size
        self.rotation = rotation
    }
}

struct WaterDroplet: View {
    let particle: WaterParticle
    let baseColor: Color
    @State private var offset = CGPoint.zero
    @State private var opacity: Double = 1.0
    @State private var scale: Double = 1.0
    
    // Cache the expensive gradient to avoid recreation
    private var cachedGradient: RadialGradient {
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
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(cachedGradient)
            
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
        // Simplified, high-performance animation - no expensive spring calculations
        let duration = PerformanceDetector.shared.enableComplexAnimations ? 0.8 : 0.5
        
        withAnimation(.easeOut(duration: duration)) {
            offset = CGPoint(
                x: particle.velocity.x,
                y: particle.velocity.y + 200
            )
            scale = 0.2
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