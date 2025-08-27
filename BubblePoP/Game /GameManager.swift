// MARK: - GameManager.swift
import SwiftUI
import Combine

enum GameResult {
    case completed
    case failed
}

class GameManager: ObservableObject {
    @Published var score = 0
    @Published var gameActive = false
    @Published var balloons: [GameBalloon] = []
    @Published var timeRemaining = 60
    @Published var waterLevel: Double = 0.0
    @Published var showPopAnimation = false
    @Published var levelComplete = false
    @Published var showLevelUp = false
    @Published var showFailure = false
    @Published var failureMessage = ""
    @Published var gameResult: GameResult?
    
    private var gameTimer: Timer?
    private var spawnTimer: Timer?
    private var balloonCount = 0
    private var positiveSpawned = 0
    private var negativeSpawned = 0
    private var currentLevel = 1
    
    func setupGame(level: Int) {
        currentLevel = level
        resetGameState()
    }
    
    func startGame() {
        gameActive = true
        score = 0
        timeRemaining = LevelConfiguration.timeAllowed(for: currentLevel)
        waterLevel = 0.0
        balloons = []
        balloonCount = 0
        positiveSpawned = 0
        negativeSpawned = 0
        levelComplete = false
        gameResult = nil
        
        startSpawning()
        startGameTimer()
    }
    
    func stopGame() {
        gameActive = false
        gameTimer?.invalidate()
        spawnTimer?.invalidate()
        balloons = []
    }
    
    func popBalloon(_ balloon: GameBalloon) {
        if balloon.isPositive {
            score += balloon.points
        } else {
            score = max(0, score - balloon.points)
        }
        
        updateWaterLevel()
        triggerPopAnimation()
        removeBalloon(balloon)
        
        if score >= LevelConfiguration.pointsNeeded(for: currentLevel) {
            completeLevel()
        }
    }
    
    private func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.timeRemaining -= 1
            if self.timeRemaining <= 0 {
                if self.score >= LevelConfiguration.pointsNeeded(for: self.currentLevel) {
                    self.completeLevel()
                } else {
                    self.failLevel()
                }
            }
        }
    }
    
    private func startSpawning() {
        let interval = LevelConfiguration.spawnInterval(for: currentLevel)
        
        spawnTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            guard self.gameActive && self.score < LevelConfiguration.pointsNeeded(for: self.currentLevel) else { return }
            self.spawnBalloon()
        }
    }
    
    private func spawnBalloon() {
        let shouldSpawnPositive = BalloonSpawner.shouldSpawnPositive(
            level: currentLevel,
            elapsedTime: Double(LevelConfiguration.timeAllowed(for: currentLevel) - timeRemaining),
            totalTime: Double(LevelConfiguration.timeAllowed(for: currentLevel)),
            positiveSpawned: positiveSpawned,
            negativeSpawned: negativeSpawned,
            pointsNeeded: LevelConfiguration.pointsNeeded(for: currentLevel)
        )
        
        let balloon = BalloonSpawner.createBalloon(
            level: currentLevel,
            isPositive: shouldSpawnPositive
        )
        
        // Update spawn counters
        if balloon.isPositive {
            positiveSpawned += balloon.points
        } else {
            negativeSpawned += balloon.points
        }
        
        // Add balloon with animation
        withAnimation(.spring(duration: GameConstants.balloonSpawnDuration, bounce: 0.6)) {
            balloons.append(balloon)
        }
        
        // Schedule removal
        let lifetime = LevelConfiguration.balloonLifetime(for: currentLevel)
        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
            self.removeBalloon(balloon)
        }
    }
    
    private func updateWaterLevel() {
        waterLevel = min(Double(score) / Double(LevelConfiguration.pointsNeeded(for: currentLevel)), 1.0)
    }
    
    private func triggerPopAnimation() {
        showPopAnimation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showPopAnimation = false
        }
    }
    
    private func removeBalloon(_ balloon: GameBalloon) {
        withAnimation(.easeOut(duration: 0.2)) {
            balloons.removeAll { $0.id == balloon.id }
        }
    }
    
    private func completeLevel() {
        gameActive = false
        gameTimer?.invalidate()
        spawnTimer?.invalidate()
        balloons = []
        levelComplete = true
        waterLevel = 1.0
        showLevelUp = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.gameResult = .completed
        }
    }
    
    private func failLevel() {
        gameActive = false
        gameTimer?.invalidate()
        spawnTimer?.invalidate()
        balloons = []
        
        failureMessage = "Time's up! Try again to improve your score."
        showFailure = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.gameResult = .failed
        }
    }
    
    private func resetGameState() {
        score = 0
        gameActive = false
        balloons = []
        timeRemaining = LevelConfiguration.timeAllowed(for: currentLevel)
        waterLevel = 0.0
        levelComplete = false
        showLevelUp = false
        showFailure = false
        failureMessage = ""
        gameResult = nil
        gameTimer?.invalidate()
        spawnTimer?.invalidate()
    }
}

// MARK: - BalloonSpawner.swift
struct BalloonSpawner {
    static func shouldSpawnPositive(
        level: Int,
        elapsedTime: Double,
        totalTime: Double,
        positiveSpawned: Int,
        negativeSpawned: Int,
        pointsNeeded: Int
    ) -> Bool {
        let progress = elapsedTime / totalTime
        let targetPositivePoints = Int(Double(pointsNeeded) * 1.8 * progress)
        let targetNegativePoints = Int(Double(pointsNeeded) * 0.6 * progress)
        
        if positiveSpawned < targetPositivePoints && negativeSpawned < targetNegativePoints {
            let bias = LevelConfiguration.positiveBias(for: level)
            return Double.random(in: 0...1) < bias
        } else if positiveSpawned < targetPositivePoints {
            return true
        } else if negativeSpawned < targetNegativePoints {
            return false
        } else {
            let bias = max(0.4, 0.7 - (Double(level) * 0.05))
            return Double.random(in: 0...1) < bias
        }
    }
    
    static func createBalloon(level: Int, isPositive: Bool) -> GameBalloon {
        let pointRange = LevelConfiguration.pointRange(for: level, isPositive: isPositive)
        
        return GameBalloon(
            x: Double.random(in: GameConstants.balloonSpawnArea.x),
            y: Double.random(in: GameConstants.balloonSpawnArea.y),
            isPositive: isPositive,
            points: Int.random(in: pointRange),
            color: GameConstants.balloonColors.randomElement() ?? GameConstants.balloonColors[0]
        )
    }
}

// MARK: - GameOverlaysView.swift
import SwiftUI

struct GameOverlaysView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        ZStack {
            if gameManager.showLevelUp {
                LevelCompleteOverlay()
                    .environmentObject(gameState)
                    .environmentObject(gameManager)
            }
            
            if gameManager.showFailure {
                LevelFailedOverlay()
                    .environmentObject(gameManager)
            }
        }
    }
}

struct LevelCompleteOverlay: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🎉 LEVEL COMPLETE! 🎉")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .orange, radius: 20)
            
            Text("Level \(gameState.selectedLevel) Complete!")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 5)
            
            Button("Continue") {
                gameManager.gameResult = .completed
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
            )
            .foregroundColor(.white)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .opacity(0.95)
                .shadow(color: .black.opacity(0.3), radius: 20)
        )
        .scaleEffect(gameManager.showLevelUp ? 1.0 : 0.1)
        .opacity(gameManager.showLevelUp ? 1.0 : 0.0)
        .animation(.spring(duration: GameConstants.levelUpAnimationDuration, bounce: 0.4), value: gameManager.showLevelUp)
    }
}

struct LevelFailedOverlay: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("⏰ TIME'S UP!")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .red, radius: 15)
            
            Text(gameManager.failureMessage)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .shadow(color: .black, radius: 3)
            
            Text("⚠️ Warning: 3 failures lock previous level")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.yellow.opacity(0.8))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Try Again") {
                    gameManager.showFailure = false
                    gameManager.startGame()
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                )
                .foregroundColor(.white)
                
                Button("Back to Home") {
                    gameManager.gameResult = .failed
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                )
                .foregroundColor(.white)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .opacity(0.95)
                .shadow(color: .black.opacity(0.4), radius: 20)
        )
        .scaleEffect(gameManager.showFailure ? 1.0 : 0.1)
        .opacity(gameManager.showFailure ? 1.0 : 0.0)
        .animation(.spring(duration: 0.5, bounce: 0.3), value: gameManager.showFailure)
    }
}

// MARK: - WaterFillView.swift
struct WaterFillView: View {
    let waterLevel: Double
    let geometry: GeometryProxy
    
    var body: some View {
        VStack {
            Spacer()
            Rectangle()
                .fill(GameConstants.waterGradient)
                .frame(height: geometry.size.height * waterLevel)
                .overlay(
                    VStack {
                        ModernWaveShape()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.cyan.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 20)
                            .animation(.easeInOut(duration: 2.0).repeatForever(), value: UUID())
                        Spacer()
                    }
                )
                .animation(.spring(duration: 0.8, bounce: 0.2), value: waterLevel)
        }
        .ignoresSafeArea()
    }
}

struct ModernWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHeight: CGFloat = 12
        let waveLength = rect.width / 4
        
        path.move(to: CGPoint(x: 0, y: rect.midY))
        
        for i in stride(from: 0, through: rect.width, by: 2) {
            let relativeX = i / waveLength
            let sine = sin(relativeX * .pi * 2)
            let cosine = cos(relativeX * .pi * 1.3)
            let y = rect.midY + (sine + cosine * 0.3) * waveHeight
            path.addLine(to: CGPoint(x: i, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}
