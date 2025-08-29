import SwiftUI

// MARK: - Static Paint Splash Effect
struct ColorSplashView: View {
    let position: CGPoint
    let color: Color
    @State private var opacity: Double = 1.0  // Start fully visible
    @State private var splatterData: [PaintDrop] = []
    
    // Generate random values once for consistent shape
    private let mainRotation: Double
    private let secondaryRotation: Double
    private let secondaryOffset: CGPoint
    
    init(position: CGPoint, color: Color) {
        self.position = position
        self.color = color
        
        // Generate random values once and store them
        let seed = Int(position.x + position.y * 1000)
        var generator = SeededRandomNumberGenerator(seed: seed)
        
        self.mainRotation = Double.random(in: 0...360, using: &generator)
        self.secondaryRotation = Double.random(in: 0...360, using: &generator)
        self.secondaryOffset = CGPoint(
            x: CGFloat.random(in: -3...3, using: &generator),
            y: CGFloat.random(in: -3...3, using: &generator)
        )
    }
    
    var body: some View {
        ZStack {
            // Main irregular paint splash - STATIC, no animation
            IrregularSplashShape(seed: 1)
                .fill(color.opacity(0.9))
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(mainRotation))
                .opacity(opacity)
            
            // Additional layer for texture and depth
            IrregularSplashShape(seed: 2)
                .fill(color.opacity(0.5))
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(secondaryRotation))
                .offset(x: secondaryOffset.x, y: secondaryOffset.y)
                .opacity(opacity * 0.7)
            
            // Third layer for more complexity
            IrregularSplashShape(seed: 3)
                .fill(color.opacity(0.3))
                .frame(width: 90, height: 90)
                .rotationEffect(.degrees(mainRotation + 45))
                .offset(x: secondaryOffset.x * -0.5, y: secondaryOffset.y * -0.5)
                .opacity(opacity * 0.6)
            
            // Paint splatters around main splash
            ForEach(splatterData) { drop in
                if drop.isRound {
                    Circle()
                        .fill(color.opacity(drop.opacityMultiplier))
                        .frame(width: drop.size, height: drop.size)
                        .offset(x: drop.offset.x, y: drop.offset.y)
                        .opacity(opacity)
                } else {
                    // Elongated splash
                    Capsule()
                        .fill(color.opacity(drop.opacityMultiplier))
                        .frame(width: drop.size * 0.3, height: drop.size)
                        .rotationEffect(.degrees(drop.rotation))
                        .offset(x: drop.offset.x, y: drop.offset.y)
                        .opacity(opacity)
                }
            }
        }
        .position(position)
        .onAppear {
            setupSplatter()
            // Just fade out - no other animation
            fadeOut()
        }
        .allowsHitTesting(false)
    }
    
    private func setupSplatter() {
        // Create paint drops radiating from center with more variation using seeded random
        let seed = Int(position.x + position.y * 1000) + 42 // Different seed than shape
        var generator = SeededRandomNumberGenerator(seed: seed)
        
        splatterData = (0..<25).map { _ in
            let distance = CGFloat.random(in: 30...120, using: &generator)
            let angle = CGFloat.random(in: 0...360, using: &generator) * .pi / 180
            let sizeVariation = Float.random(in: 0...1, using: &generator)
            
            // Create different types of splatters
            let (size, isRound, opacity): (CGFloat, Bool, Double) = {
                if sizeVariation > 0.85 {
                    // Large main splatters
                    return (CGFloat.random(in: 8...16, using: &generator), Bool.random(using: &generator), Double.random(in: 0.6...0.9, using: &generator))
                } else if sizeVariation > 0.6 {
                    // Medium splatters
                    return (CGFloat.random(in: 4...10, using: &generator), Bool.random(using: &generator), Double.random(in: 0.5...0.8, using: &generator))
                } else {
                    // Small droplets
                    return (CGFloat.random(in: 1...4, using: &generator), true, Double.random(in: 0.3...0.6, using: &generator))
                }
            }()
            
            return PaintDrop(
                offset: CGPoint(
                    x: cos(angle) * distance,
                    y: sin(angle) * distance  
                ),
                size: size,
                scaleMultiplier: 1.0,  // No scaling - static
                opacityMultiplier: opacity,
                isRound: isRound,
                rotation: Double.random(in: 0...360, using: &generator)
            )
        }
    }
    
    private func fadeOut() {
        // Static splash - stays visible longer then fades out
        withAnimation(.linear(duration: 1.5).delay(1.0)) {
            opacity = 0.0
        }
    }
}

// More realistic irregular splash shape with consistent randomness
struct IrregularSplashShape: Shape {
    let seed: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2
        
        // Use seed for consistent but different shapes
        var generator = SeededRandomNumberGenerator(seed: seed)
        
        // Create very irregular splash with multiple blob areas and tendrils
        let numPoints = 36 // More points for finer detail
        var points: [CGPoint] = []
        
        for i in 0..<numPoints {
            let angle = (CGFloat(i) * 2.0 * .pi) / CGFloat(numPoints)
            
            // Create more extreme variations for realistic splash
            let spikeChance = Float.random(in: 0...1, using: &generator)
            let baseVariation = CGFloat.random(in: 0.4...0.9, using: &generator)
            
            let radius: CGFloat
            if spikeChance > 0.9 {
                // Very long tendril/spike
                radius = baseRadius * CGFloat.random(in: 1.5...2.2, using: &generator)
            } else if spikeChance > 0.75 {
                // Medium tendril
                radius = baseRadius * CGFloat.random(in: 1.1...1.6, using: &generator)
            } else if spikeChance > 0.6 {
                // Small protrusion
                radius = baseRadius * CGFloat.random(in: 0.9...1.2, using: &generator)
            } else if spikeChance < 0.15 {
                // Deep indent creating void spaces
                radius = baseRadius * CGFloat.random(in: 0.1...0.4, using: &generator)
            } else if spikeChance < 0.3 {
                // Medium indent
                radius = baseRadius * CGFloat.random(in: 0.4...0.7, using: &generator)
            } else {
                // Main blob area
                radius = baseRadius * baseVariation
            }
            
            // Add organic noise and asymmetry
            let noiseX = CGFloat.random(in: -5...5, using: &generator)
            let noiseY = CGFloat.random(in: -5...5, using: &generator)
            
            // Create slight elongation for more natural shape
            let elongationFactor = CGFloat.random(in: 0.85...1.15, using: &generator)
            let adjustedRadius = radius * (angle < .pi ? elongationFactor : 1.0 / elongationFactor)
            
            let x = center.x + cos(angle) * adjustedRadius + noiseX
            let y = center.y + sin(angle) * adjustedRadius + noiseY
            points.append(CGPoint(x: x, y: y))
        }
        
        // Create organic curves through points
        if !points.isEmpty {
            path.move(to: points[0])
            
            for i in 0..<points.count {
                let nextIndex = (i + 1) % points.count
                let nextNextIndex = (i + 2) % points.count
                
                // Use quadratic curves for more organic feel
                let controlPoint = CGPoint(
                    x: (points[nextIndex].x + points[nextNextIndex].x) / 2,
                    y: (points[nextIndex].y + points[nextNextIndex].y) / 2
                )
                
                path.addQuadCurve(to: points[nextIndex], control: controlPoint)
            }
            
            path.closeSubpath()
        }
        
        return path
    }
}

// Simple seeded random generator for consistent shapes
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var seed: UInt64
    
    init(seed: Int) {
        self.seed = UInt64(abs(seed))
    }
    
    mutating func next() -> UInt64 {
        seed = seed &* 2862933555777941757 &+ 3037000493
        return seed
    }
}

struct PaintDrop: Identifiable {
    let id = UUID()
    let offset: CGPoint
    let size: CGFloat
    let scaleMultiplier: Double
    let opacityMultiplier: Double
    let isRound: Bool
    let rotation: Double
}

// MARK: - Background Color Flash
struct BackgroundColorFlash: View {
    let color: Color
    @State private var opacity: Double = 0.0
    
    var body: some View {
        Rectangle()
            .fill(color.opacity(0.15))
            .opacity(opacity)
            .ignoresSafeArea()
            .onAppear {
                // Quick background flash
                withAnimation(.easeOut(duration: 0.1)) {
                    opacity = 1.0
                }
                
                withAnimation(.easeOut(duration: 0.2).delay(0.05)) {
                    opacity = 0.0
                }
            }
            .allowsHitTesting(false) // Don't interfere with game interactions
    }
}