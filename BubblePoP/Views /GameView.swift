// MARK: - GameView.swift
import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameState: GameState
    @StateObject private var gameManager = GameManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Enhanced background
                ZStack {
                    GameConstants.backgroundGradient
                    
                    // Animated bubbles in background
                    BackgroundBubbles()
                }
                .ignoresSafeArea()
                
                // Water fill effect
                WaterFillView(waterLevel: gameManager.waterLevel, geometry: geometry)
                
                VStack(spacing: 0) {
                    // Header
                    GameHeaderView()
                        .environmentObject(gameState)
                        .environmentObject(gameManager)
                        .background(
                            .ultraThinMaterial
                                .opacity(0.3)
                        )
                    
                    // Game stats
                    GameStatsView()
                        .environmentObject(gameState)
                        .environmentObject(gameManager)
                    
                    // Game area
                    GameAreaView()
                        .environmentObject(gameManager)
                    
                    // Controls
                    GameControlsView()
                        .environmentObject(gameState)
                        .environmentObject(gameManager)
                }
                
                // Overlays
                GameOverlaysView()
                    .environmentObject(gameState)
                    .environmentObject(gameManager)
            }
        }
        .onAppear {
            gameManager.setupGame(level: gameState.selectedLevel)
        }
        .onChange(of: gameManager.gameResult) { _, result in
            handleGameResult(result)
        }
    }
    
    private func handleGameResult(_ result: GameResult?) {
        guard let result = result else { return }
        
        switch result {
        case .completed:
            // Complete level immediately for unlock logic
            gameState.completeLevel(gameState.selectedLevel)
            // Don't go home yet - let the overlay handle it
        case .failed:
            gameState.failLevel(gameState.selectedLevel)
            // Don't go home yet - let the overlay handle it
        }
    }
}

// MARK: - GameHeaderView.swift
struct GameHeaderView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack {
            BackButton { gameState.goHome() }
            
            Spacer()
            
            LevelIndicator(level: gameState.selectedLevel)
        }
        .padding()
    }
}

struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                Text("Home")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .opacity(0.7)
            )
        }
    }
}

struct LevelIndicator: View {
    let level: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Level \(level)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .opacity(0.8)
        )
    }
}

// MARK: - GameStatsView.swift
struct GameStatsView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var gameManager: GameManager
    
    private var pointsNeeded: Int {
        LevelConfiguration.pointsNeeded(for: gameState.selectedLevel)
    }
    
    var body: some View {
        HStack {
            ScoreSection(
                score: gameManager.score,
                pointsNeeded: pointsNeeded
            )
            
            Spacer()
            
            TimerSection(
                timeRemaining: gameManager.timeRemaining,
                isComplete: gameManager.levelComplete
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .opacity(0.8)
        )
    }
}

struct ScoreSection: View {
    let score: Int
    let pointsNeeded: Int
    @State private var displayScore: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(displayScore)/\(pointsNeeded)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .cyan.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                )
                .contentTransition(.numericText())
            
            ProgressView(value: Double(min(displayScore, pointsNeeded)), total: Double(pointsNeeded))
                .progressViewStyle(.linear)
                .tint(.cyan)
                .scaleEffect(y: 3)
                .frame(width: 120)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: displayScore)
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                displayScore = newValue
            }
        }
        .onAppear {
            displayScore = score
        }
    }
}

struct TimerSection: View {
    let timeRemaining: Int
    let isComplete: Bool
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if isComplete {
                Text("COMPLETE!")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: .green, radius: 10)
            } else {
                Text("\(timeRemaining)s")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .pink.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    )
            }
        }
    }
}

// MARK: - GameAreaView.swift
struct GameAreaView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Balloons
            ForEach(gameManager.balloons) { balloon in
                BalloonView(balloon: balloon) {
                    gameManager.popBalloon(balloon)
                }
            }
            
            // Water burst effects
            ForEach(gameManager.popEffects) { effect in
                WaterBurstView(position: effect.position, color: effect.color)
                    .allowsHitTesting(false)
                    .onAppear {
                        if !effect.isPositive {
                            shakeScreen()
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(x: shakeOffset)
    }
    
    private func shakeScreen() {
        withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
            shakeOffset = 5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shakeOffset = 0
        }
    }
}


// MARK: - GameControlsView.swift
struct GameControlsView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var gameManager: GameManager
    
    private var pointsNeeded: Int {
        LevelConfiguration.pointsNeeded(for: gameState.selectedLevel)
    }
    
    private var timeAllowed: Int {
        LevelConfiguration.timeAllowed(for: gameState.selectedLevel)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if !gameManager.gameActive && !gameManager.levelComplete && !gameManager.showFailure {
                Text("Get \(pointsNeeded) points in \(timeAllowed) seconds")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            if !gameManager.levelComplete && !gameManager.showFailure {
                GameButton(
                    isActive: gameManager.gameActive,
                    level: gameState.selectedLevel
                ) {
                    if gameManager.gameActive {
                        gameManager.stopGame()
                    } else {
                        gameManager.startGame()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .opacity(0.6)
        )
        .padding()
    }
}

struct GameButton: View {
    let isActive: Bool
    let level: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isActive ? "stop.fill" : "play.fill")
                    .font(.title3)
                Text(isActive ? "Stop" : "Start Level \(level)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isActive ?
                                [.red.opacity(0.8), .pink.opacity(0.6)] :
                                [.green.opacity(0.8), .mint.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: isActive ? .red.opacity(0.3) : .green.opacity(0.3),
                        radius: 10
                    )
            )
            .foregroundColor(.white)
        }
        .scaleEffect(isActive ? 0.95 : 1.0)
        .animation(.spring(duration: 0.2), value: isActive)
    }
}
