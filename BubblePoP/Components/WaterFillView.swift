import SwiftUI

struct WaterFillView: View {
    let waterLevel: Double
    let geometry: GeometryProxy
    @State private var waveOffset: Double = 0
    @State private var waveOffset2: Double = 0
    
    var body: some View {
        ZStack {
            // Primary wave
            WaveShape(offset: waveOffset, percent: waterLevel, amplitude: 10, frequency: 0.8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.6),
                            Color.blue.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            
            // Secondary wave for depth
            WaveShape(offset: waveOffset2, percent: waterLevel, amplitude: 8, frequency: 1.2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.4),
                            Color.cyan.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Bubbles in water
            if waterLevel > 0 {
                WaterBubbles(waterLevel: waterLevel, geometry: geometry)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                waveOffset = 360
            }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                waveOffset2 = 360
            }
        }
    }
}

struct WaveShape: Shape {
    var offset: Double
    var percent: Double
    var amplitude: Double
    var frequency: Double
    
    var animatableData: Double {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHeight = amplitude
        let yOffset = rect.height * (1 - percent)
        let startAngle = offset * .pi / 180
        
        path.move(to: CGPoint(x: 0, y: yOffset))
        
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let angle = relativeX * frequency * 2 * .pi + startAngle
            let y = yOffset + sin(angle) * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

struct WaterBubbles: View {
    let waterLevel: Double
    let geometry: GeometryProxy
    @State private var bubbles: [Bubble] = []
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            ForEach(bubbles) { bubble in
                BubbleView(bubble: bubble, waterLevel: waterLevel, geometry: geometry)
            }
        }
        .onAppear {
            createInitialBubbles()
        }
        .onReceive(timer) { _ in
            if waterLevel > 0.1 && Bool.random() {
                createBubble()
            }
            cleanupBubbles()
        }
    }
    
    private func createInitialBubbles() {
        bubbles = (0..<3).map { _ in
            Bubble(
                x: Double.random(in: 50...geometry.size.width - 50),
                startY: geometry.size.height * (1 - waterLevel + 0.1),
                size: Double.random(in: 4...8),
                duration: Double.random(in: 2...4)
            )
        }
    }
    
    private func createBubble() {
        let bubble = Bubble(
            x: Double.random(in: 50...geometry.size.width - 50),
            startY: geometry.size.height * (1 - waterLevel + 0.1),
            size: Double.random(in: 4...8),
            duration: Double.random(in: 2...4)
        )
        bubbles.append(bubble)
    }
    
    private func cleanupBubbles() {
        bubbles = bubbles.filter { bubble in
            bubble.createdAt.timeIntervalSinceNow > -bubble.duration
        }
    }
}

struct Bubble: Identifiable {
    let id = UUID()
    let x: Double
    let startY: Double
    let size: Double
    let duration: Double
    let createdAt = Date()
}

struct BubbleView: View {
    let bubble: Bubble
    let waterLevel: Double
    let geometry: GeometryProxy
    @State private var yOffset: Double = 0
    @State private var xOffset: Double = 0
    @State private var opacity: Double = 0.6
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(opacity))
            .frame(width: bubble.size, height: bubble.size)
            .position(x: bubble.x + xOffset, y: bubble.startY + yOffset)
            .onAppear {
                withAnimation(.linear(duration: bubble.duration)) {
                    yOffset = -bubble.startY + geometry.size.height * (1 - waterLevel)
                    opacity = 0
                }
                withAnimation(.easeInOut(duration: bubble.duration / 2).repeatForever(autoreverses: true)) {
                    xOffset = Double.random(in: -10...10)
                }
            }
    }
}