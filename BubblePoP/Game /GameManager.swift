// MARK: - GameManager.swift
import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif

enum GameResult {
    case completed
    case failed
}

struct PopEffect: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let isPositive: Bool
}

class GameManager: ObservableObject {
    @Published var score = 0
    @Published var gameActive = false
    @Published var balloons: [GameBalloon] = []
    @Published var timeRemaining = 60
    @Published var waterLevel: Double = 0.0
    @Published var showPopAnimation = false
    @Published var popEffects: [PopEffect] = []
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
        triggerPopAnimation(at: CGPoint(x: balloon.x, y: balloon.y), color: balloon.color, isPositive: balloon.isPositive)
        removeBalloon(balloon)
        
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: balloon.isPositive ? .light : .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        #endif
        
        if score >= LevelConfiguration.pointsNeeded(for: currentLevel) {
            completeLevel()
        }
    }
    
    func retryLevel() {
        showFailure = false
        startGame()
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
    
    private func triggerPopAnimation(at position: CGPoint, color: Color, isPositive: Bool) {
        let effect = PopEffect(position: position, color: color, isPositive: isPositive)
        popEffects.append(effect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.popEffects.removeAll { $0.id == effect.id }
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
        
        print("🎊 Setting showLevelUp = true, should show overlay now")
        
        // Delay setting gameResult so overlay can show first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        
        // Set result immediately
        gameResult = .failed
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