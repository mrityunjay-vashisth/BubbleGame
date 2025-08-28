import SwiftUI
#if os(iOS)
import UIKit
#endif

struct BackgroundBubbles: View {
    @State private var bubbles: [BackgroundBubble] = []
    @State private var lastSpawnTime: Date = Date()
    private let maxBubbles = PerformanceDetector.shared.backgroundBubbleCount
    private let spawnInterval: TimeInterval = 3.0 // Slower spawn rate
    
    var body: some View {
        ZStack {
            ForEach(bubbles) { bubble in
                BubbleShape(bubble: bubble)
            }
        }
        .onAppear {
            createInitialBubbles()
            startEfficientSpawning()
        }
    }
    
    private func createInitialBubbles() {
        let initialCount = min(3, PerformanceDetector.shared.backgroundBubbleCount)
        bubbles = (0..<initialCount).map { _ in  // Performance-adjusted count
            BackgroundBubble(
                position: CGPoint(
                    x: Double.random(in: 50...350),
                    y: Double.random(in: 100...700)
                ),
                size: Double.random(in: 20...35),  // Smaller size range
                opacity: Double.random(in: 0.03...0.06),  // Reduced opacity range
                animationDuration: Double.random(in: 25...35)  // Longer animations
            )
        }
    }
    
    private func startEfficientSpawning() {
        // Use a more efficient approach without continuous timers
        spawnBubbleIfNeeded()
    }
    
    private func spawnBubbleIfNeeded() {
        let now = Date()
        
        // Only spawn if we have fewer bubbles and enough time has passed
        if bubbles.count < maxBubbles && now.timeIntervalSince(lastSpawnTime) >= spawnInterval {
            let bubble = BackgroundBubble(
                position: CGPoint(
                    x: Double.random(in: 50...350),
                    y: 900
                ),
                size: Double.random(in: 20...35),
                opacity: Double.random(in: 0.03...0.06),
                animationDuration: Double.random(in: 25...35)
            )
            bubbles.append(bubble)
            lastSpawnTime = now
            
            // Schedule next spawn check
            DispatchQueue.main.asyncAfter(deadline: .now() + spawnInterval) {
                self.cleanupAndSpawn()
            }
        }
    }
    
    private func cleanupAndSpawn() {
        // Clean up expired bubbles
        bubbles = bubbles.filter { bubble in
            bubble.createdAt.timeIntervalSinceNow > -40  // Longer cleanup interval
        }
        
        // Try to spawn new bubble
        spawnBubbleIfNeeded()
    }
}

struct BackgroundBubble: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: Double
    let opacity: Double
    let animationDuration: Double
    let createdAt = Date()
}

struct BubbleShape: View {
    let bubble: BackgroundBubble
    @State private var yOffset: Double = 0
    @State private var xOffset: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                Color.cyan.opacity(bubble.opacity * 0.3)
            )
            .blur(radius: 2)
            .frame(width: bubble.size, height: bubble.size)
            .position(bubble.position)
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                withAnimation(.linear(duration: bubble.animationDuration)) {
                    yOffset = -1000
                }
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    xOffset = Double.random(in: -30...30)
                }
            }
    }
}