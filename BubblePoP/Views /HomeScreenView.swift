// MARK: - HomeScreenView.swift
import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject var gameState: GameState
    
    private let columns = Array(repeating: GridItem(.flexible()), count: GameConstants.levelGridColumns)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                GameConstants.backgroundGradient
                    .ignoresSafeArea()
                
                // Floating particles
                FloatingParticlesView(geometry: geometry, count: gameState.unlockedLevels.count)
                
                ScrollView {
                    VStack(spacing: 30) {
                        HeaderView(
                            completedCount: gameState.completedLevels.count,
                            unlockedCount: gameState.unlockedLevels.count
                        )
                        
                        LevelGridView()
                            .environmentObject(gameState)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
    }
}

struct HeaderView: View {
    let completedCount: Int
    let unlockedCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🎈 Balloon Pop")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .blue.opacity(0.5), radius: 10)
            
            Text("Select Your Level")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            // Progress indicator
            HStack(spacing: 12) {
                ProgressBadge(
                    icon: "trophy.fill",
                    color: .yellow,
                    label: "Completed",
                    count: completedCount
                )
                
                ProgressBadge(
                    icon: "lock.open.fill",
                    color: .green,
                    label: "Unlocked",
                    count: unlockedCount
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .opacity(0.6)
            )
        }
        .padding(.top, 20)
    }
}

struct ProgressBadge: View {
    let icon: String
    let color: Color
    let label: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(label): \(count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

struct FloatingParticlesView: View {
    let geometry: GeometryProxy
    let count: Int
    
    var body: some View {
        ForEach(0..<15, id: \.self) { i in
            Circle()
                .fill(Color.cyan.opacity(0.1))
                .frame(width: CGFloat.random(in: 20...40))
                .position(
                    x: CGFloat.random(in: 0...geometry.size.width),
                    y: CGFloat.random(in: 0...geometry.size.height)
                )
                .animation(.easeInOut(duration: Double.random(in: 4...10)).repeatForever(), value: count)
        }
    }
}

struct LevelGridView: View {
    @EnvironmentObject var gameState: GameState
    
    private let columns = Array(repeating: GridItem(.flexible()), count: GameConstants.levelGridColumns)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(1...GameConstants.maxLevels, id: \.self) { level in
                LevelBoxView(level: level)
                    .environmentObject(gameState)
            }
        }
        .padding(.horizontal, 20)
    }
}
