// MARK: - GameView.swift
import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameState: GameState
    @StateObject private var gameManager = GameManager()
    @State private var lowMemoryMode = false
    @State private var lastGameResult: GameResult? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Background (furthest back)
                ZStack {
                    GameConstants.backgroundGradient
                    
                    // Animated bubbles in background
                    BackgroundBubbles()
                }
                .ignoresSafeArea()
                .zIndex(0)
                
                // Layer 2: Water fill effect
                WaterFillView(waterLevel: gameManager.waterLevel, geometry: geometry)
                    .zIndex(1)
                
                // Layer 3: Game play area (balloons spawn here)
                GameAreaView()
                    .environmentObject(gameManager)
                    .zIndex(2)
                
                // Layer 4: UI Controls (always on top)
                VStack(spacing: 0) {
                    // Header
                    GameHeaderView()
                        .environmentObject(gameState)
                        .environmentObject(gameManager)
                        .background(.ultraThinMaterial.opacity(0.8))
                    
                    // Game stats
                    GameStatsView()
                        .environmentObject(gameState)
                        .environmentObject(gameManager)
                    
                    Spacer() // Push controls to bottom
                    
                    // Controls
                    GameControlsView()
                        .environmentObject(gameState)
                        .environmentObject(gameManager)
                }
                .zIndex(3)
                
                // Layer 5: Overlays (highest priority)
                GameOverlaysView()
                    .environmentObject(gameState)
                    .environmentObject(gameManager)
                    .zIndex(4)
                
                // Debug spawn area (development only)
                SpawnAreaDebugView(
                    screenSize: geometry.size,
                    showBounds: GameConstants.showSpawnAreaBounds
                )
                .zIndex(5)
            }
            .onAppear {
                // Use geometry size from GeometryReader context
                let screenSize = geometry.size
                gameManager.setupGame(level: gameState.selectedLevel, screenSize: screenSize)
                setupMemoryWarningHandling()
            }
        }
        .onChange(of: gameManager.gameResult) { _, result in
            // Prevent handling the same result multiple times per frame
            guard result != lastGameResult else { return }
            lastGameResult = result
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
    
    private func setupMemoryWarningHandling() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            handleMemoryWarning()
        }
        #endif
    }
    
    private func handleMemoryWarning() {
        // Enable low memory mode
        lowMemoryMode = true
        
        // Force cleanup in game manager
        if gameManager.gameActive {
            // Reduce visual effects temporarily
            gameManager.popEffects.removeAll()
        }
        
        // Reset low memory mode after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            lowMemoryMode = false
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
            .foregroundColor(GameConstants.UI.primaryText)
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

// MARK: - Futuristic Game Stats
struct GameStatsView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var gameManager: GameManager
    @State private var pulseAnimation = false
    
    private var pointsNeeded: Int {
        LevelConfiguration.pointsNeeded(for: gameState.selectedLevel)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Futuristic Score Display
            FuturisticScoreDisplay(
                score: gameManager.score,
                pointsNeeded: pointsNeeded,
                pulseAnimation: $pulseAnimation
            )
            
            Spacer()
            
            // Futuristic Timer Display
            FuturisticTimerDisplay(
                timeRemaining: gameManager.timeRemaining,
                isComplete: gameManager.levelComplete
            )
            .environmentObject(gameManager)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [GameConstants.UI.accent.opacity(0.3), GameConstants.UI.success.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: GameConstants.UI.accent.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Futuristic Score Display
struct FuturisticScoreDisplay: View {
    let score: Int
    let pointsNeeded: Int
    @Binding var pulseAnimation: Bool
    @State private var displayScore: Int = 0
    @State private var progressAnimation = false
    
    private var progress: Double {
        Double(min(displayScore, pointsNeeded)) / Double(pointsNeeded)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Score Label
            Text("SCORE")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(GameConstants.UI.secondaryText)
                .tracking(1.2)
            
            // Score Display with Animation
            HStack(spacing: 8) {
                Text("\(displayScore)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [GameConstants.UI.accent, GameConstants.UI.warning],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .contentTransition(.numericText())
                    .scaleEffect(progressAnimation ? 1.05 : 1.0)
                
                Text("/")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(GameConstants.UI.tertiaryText)
                
                Text("\(pointsNeeded)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(GameConstants.UI.secondaryText)
            }
            
            // Futuristic Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(GameConstants.UI.divider)
                        .frame(height: 8)
                    
                    // Progress fill with gradient
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    GameConstants.UI.success,
                                    GameConstants.UI.accent,
                                    GameConstants.UI.warning
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .shadow(color: GameConstants.UI.accent.opacity(0.5), radius: 4, x: 0, y: 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                    
                    // Glow effect at progress end
                    if progress > 0 {
                        Circle()
                            .fill(GameConstants.UI.accent)
                            .frame(width: 12, height: 12)
                            .blur(radius: pulseAnimation ? 6 : 3)
                            .offset(x: max(0, geometry.size.width * progress - 6))
                    }
                }
            }
            .frame(width: 150, height: 8)
        }
        .onChange(of: score) { _, newValue in
            // Instant, responsive score updates
            withAnimation(.easeOut(duration: 0.15)) {
                displayScore = newValue
                progressAnimation = true
            }
            
            // Quick pulse reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                progressAnimation = false
            }
        }
        .onAppear {
            displayScore = score
        }
    }
}

// MARK: - Futuristic Timer Display
struct FuturisticTimerDisplay: View {
    let timeRemaining: Int
    let isComplete: Bool
    @EnvironmentObject var gameManager: GameManager
    @State private var timerPulse = false
    @State private var criticalTime = false
    @State private var lastTimeUpdate: Int = -1
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Timer Label
            Text(isComplete ? "STATUS" : "TIME")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(GameConstants.UI.secondaryText)
                .tracking(1.2)
            
            if isComplete {
                // Completion Status
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(GameConstants.UI.success)
                    
                    Text("DONE")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [GameConstants.UI.success, GameConstants.UI.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .scaleEffect(timerPulse ? 1.1 : 1.0)
            } else {
                // Circular Timer Display
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(GameConstants.UI.divider, lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    // Timer progress circle
                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / 60.0)
                        .stroke(
                            LinearGradient(
                                colors: criticalTime ? 
                                    [GameConstants.UI.danger, GameConstants.UI.warning] :
                                    [GameConstants.UI.accent, GameConstants.UI.success],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: criticalTime ? GameConstants.UI.danger.opacity(0.5) : GameConstants.UI.accent.opacity(0.3), radius: 4)
                    
                    // Time text
                    VStack(spacing: 0) {
                        Text("\(timeRemaining)")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: criticalTime ?
                                        [GameConstants.UI.danger, GameConstants.UI.warning] :
                                        [GameConstants.UI.primaryText, GameConstants.UI.secondaryText],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("sec")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(GameConstants.UI.tertiaryText)
                    }
                    .scaleEffect(timerPulse ? 1.05 : 1.0)
                }
                
                // Time adjustment feedback
                if gameManager.timeAdjustment != 0 {
                    Text("\(gameManager.timeAdjustment > 0 ? "+" : "")\(gameManager.timeAdjustment) sec")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(gameManager.timeAdjustment > 0 ? .green : .red)
                        .scaleEffect(1.2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onChange(of: timeRemaining) { _, newValue in
            // Only update if time actually changed to prevent multiple updates per frame
            guard newValue != lastTimeUpdate else { return }
            lastTimeUpdate = newValue
            
            if newValue <= 10 && !criticalTime {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    criticalTime = true
                    timerPulse = true
                }
            }
        }
        .onChange(of: isComplete) { _, _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                timerPulse = true
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
            .foregroundColor(GameConstants.UI.primaryText)
        }
        .scaleEffect(isActive ? 0.95 : 1.0)
        .animation(.spring(duration: 0.2), value: isActive)
    }
}
