import SwiftUI
#if os(iOS)
import UIKit
#endif

struct BackgroundBubbles: View {
    @State private var bubbles: [BackgroundBubble] = []
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            ForEach(bubbles) { bubble in
                BubbleShape(bubble: bubble)
            }
        }
        .onAppear {
            createInitialBubbles()
        }
        .onReceive(timer) { _ in
            createNewBubble()
            cleanupBubbles()
        }
    }
    
    private func createInitialBubbles() {
        bubbles = (0..<5).map { _ in
            BackgroundBubble(
                position: CGPoint(
                    x: Double.random(in: 50...350),
                    y: Double.random(in: 100...700)
                ),
                size: Double.random(in: 15...40),
                opacity: Double.random(in: 0.02...0.08),
                animationDuration: Double.random(in: 20...30)
            )
        }
    }
    
    private func createNewBubble() {
        let bubble = BackgroundBubble(
            position: CGPoint(
                x: Double.random(in: 50...350),
                y: 900
            ),
            size: Double.random(in: 15...40),
            opacity: Double.random(in: 0.02...0.08),
            animationDuration: Double.random(in: 20...30)
        )
        bubbles.append(bubble)
    }
    
    private func cleanupBubbles() {
        bubbles = bubbles.filter { bubble in
            bubble.createdAt.timeIntervalSinceNow > -30
        }
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