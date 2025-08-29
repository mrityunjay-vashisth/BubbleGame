// MARK: - GameManager.swift
import SwiftUI
import Combine
import AudioToolbox
#if os(iOS)
import UIKit
#endif

enum GameResult {
    case completed
    case failed
}

// MARK: - SoundManager
class SoundManager {
    static let shared = SoundManager()
    
    // System sound IDs for different balloon pop sounds
    private let positiveBalloonSound: SystemSoundID = 1057 // "Tink" sound - light and pleasant
    private let negativeBalloonSound: SystemSoundID = 1053 // "Pop" sound - deeper
    private let levelCompleteSound: SystemSoundID = 1025   // "Camera shutter" - success sound
    
    private init() {}
    
    func playPositivePop() {
        AudioServicesPlaySystemSound(positiveBalloonSound)
    }
    
    func playNegativePop() {
        AudioServicesPlaySystemSound(negativeBalloonSound)
    }
    
    func playLevelComplete() {
        AudioServicesPlaySystemSound(levelCompleteSound)
    }
}

struct PopEffect: Identifiable {
    let id: Int
    let position: CGPoint
    let color: Color
    let isPositive: Bool
    
    // Static counter for efficient ID generation (much faster than UUID)
    private static var nextID: Int = 0
    
    init(position: CGPoint, color: Color, isPositive: Bool) {
        PopEffect.nextID += 1
        self.id = PopEffect.nextID
        self.position = position
        self.color = color
        self.isPositive = isPositive
    }
}

struct ColorSplash: Identifiable {
    let id: Int
    let position: CGPoint
    let color: Color
    
    // Static counter for efficient ID generation
    private static var nextID: Int = 0
    
    init(position: CGPoint, color: Color) {
        ColorSplash.nextID += 1
        self.id = ColorSplash.nextID
        self.position = position
        self.color = color
    }
}

class GameManager: ObservableObject {
    @Published var score = 0
    @Published var gameActive = false
    @Published var balloons: [GameBalloon] = []
    @Published var timeRemaining = 60
    @Published var showPopAnimation = false
    @Published var popEffects: [PopEffect] = []
    private let maxPopEffects = PerformanceDetector.shared.maxConcurrentEffects
    @Published var levelComplete = false
    @Published var showLevelUp = false
    @Published var showFailure = false
    @Published var failureMessage = ""
    @Published var gameResult: GameResult?
    @Published var currentLevelStats = GameStatistics()
    @Published var starRating: Int = 0
    @Published var timeAdjustment: Int = 0 // For visual feedback of time changes
    @Published var colorSplashes: [ColorSplash] = [] // For background color effects
    
    // Timer for clearing time adjustment feedback to prevent memory leaks
    private var timeAdjustmentTimer: Timer?
    
    // Simple balloon management
    
    private var mainGameTimer: Timer?
    private var spawnTimer: Timer?
    private var lastSpawnTime: Date = Date()
    private var spawnInterval: TimeInterval = 0.4
    private var lastSecondUpdate: Int = 0
    private var balloonCount = 0
    private var positiveSpawned = 0
    private var negativeSpawned = 0
    private var currentLevel = 1
    
    // Optimized distribution tracking
    private var recentSpawnPositions: [CGPoint] = []
    private let minSpawnDistance: Double = 50.0
    private var precomputedPositions: [CGPoint] = [] // Cache valid positions
    private var positionIndex: Int = 0
    private var sessionStartTime: Date = Date()
    private var lastMemoryCleanup: Date = Date()
    private var initialTimeLimit: Int = 60 // Store original time limit for capping
    
    func setupGame(level: Int, screenSize: CGSize = CGSize(width: 393, height: 852)) {
        currentLevel = level
        precomputeSpawnPositions(screenSize: screenSize) // Cache positions for better performance
        resetGameState()
    }
    
    func startGame() {
        gameActive = true
        score = 0
        timeRemaining = LevelConfiguration.timeAllowed(for: currentLevel)
        initialTimeLimit = timeRemaining // Store the initial time limit
        balloons = []
        balloonCount = 0
        positiveSpawned = 0
        negativeSpawned = 0
        levelComplete = false
        gameResult = nil
        recentSpawnPositions = [] // Clear spawn history
        currentLevelStats = GameStatistics()
        starRating = 0
        timeAdjustment = 0
        
        // Reset memory management timestamps
        sessionStartTime = Date()
        lastMemoryCleanup = Date()
        
        startGameTimer()
    }
    
    func stopGame() {
        gameActive = false
        mainGameTimer?.invalidate()
        spawnTimer?.invalidate()
        timeAdjustmentTimer?.invalidate()
        balloons = []
        popEffects.removeAll() // Clear effects when stopping
        colorSplashes.removeAll() // Clear color splashes when stopping
    }
    
    func popBalloon(_ balloon: GameBalloon) {
        if balloon.isPositive {
            score += balloon.points
            currentLevelStats.positiveBalloonsPopped += 1
            // Reward correct balloon with time bonus
            adjustTime(isPositive: true)
            // Play positive pop sound
            SoundManager.shared.playPositivePop()
        } else {
            score = max(0, score - balloon.points)
            currentLevelStats.negativeBalloonsPopped += 1
            // Penalize wrong balloon with time loss
            adjustTime(isPositive: false)
            // Play negative pop sound
            SoundManager.shared.playNegativePop()
        }
        currentLevelStats.totalBalloonsPopped += 1
        
        triggerPopAnimation(at: CGPoint(x: balloon.x, y: balloon.y), color: balloon.color, isPositive: balloon.isPositive)
        triggerColorSplash(at: CGPoint(x: balloon.x, y: balloon.y), color: balloon.color)
        
        // Simple balloon removal
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
        // Reset all overlay states
        showFailure = false
        showLevelUp = false
        levelComplete = false
        gameResult = nil
        
        startGame()
    }
    
    private func adjustTime(isPositive: Bool) {
        let adjustment: Int
        
        if isPositive {
            // Correct balloon: add 1-2 seconds
            adjustment = Int.random(in: 1...2)
            timeRemaining = min(timeRemaining + adjustment, initialTimeLimit) // Cap at initial time
        } else {
            // Wrong balloon: subtract 3-5 seconds
            adjustment = Int.random(in: 3...5)
            timeRemaining = max(0, timeRemaining - adjustment) // Don't go below 0
        }
        
        // Store the adjustment for visual feedback
        timeAdjustment = isPositive ? adjustment : -adjustment
        
        // Clear existing timer to prevent multiple timers
        timeAdjustmentTimer?.invalidate()
        
        // Use proper timer instead of DispatchQueue to prevent memory leaks
        timeAdjustmentTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.timeAdjustment = 0
            self?.timeAdjustmentTimer = nil
        }
    }
    
    private func startGameTimer() {
        spawnInterval = LevelConfiguration.spawnInterval(for: currentLevel)
        lastSpawnTime = Date()
        lastSecondUpdate = Int(Date().timeIntervalSince1970)
        
        // Efficient 1-second timer for time updates
        mainGameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimeAndCleanup()
        }
        
        // Separate timer for spawning at the required interval
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { [weak self] _ in
            self?.handleSpawning()
        }
    }
    
    private func updateTimeAndCleanup() {
        guard gameActive else { return }
        
        // Update time once per second
        timeRemaining -= 1
        
        // Simple cleanup every 5 seconds
        if timeRemaining % 5 == 0 {
            cleanupExpiredEffects()
        }
        
        // Check win/lose condition
        if timeRemaining <= 0 {
            if score >= LevelConfiguration.pointsNeeded(for: currentLevel) {
                completeLevel()
            } else {
                failLevel()
            }
            return
        }
    }
    
    private func handleSpawning() {
        guard gameActive else { return }
        guard balloons.count < 8 else { return }
        guard score < LevelConfiguration.pointsNeeded(for: currentLevel) else { return }
        
        spawnBalloon()
    }
    
    private func cleanupExpiredEffects() {
        // Keep effect count reasonable
        if popEffects.count > maxPopEffects {
            popEffects = Array(popEffects.suffix(maxPopEffects))
        }
        
        // Clean up old spawn positions
        if recentSpawnPositions.count > 6 {
            recentSpawnPositions = Array(recentSpawnPositions.suffix(6))
        }
    }
    
    // Removed - no longer needed with simplified approach
    
    private func precomputeSpawnPositions(screenSize: CGSize = CGSize(width: 393, height: 852)) {
        // Pre-calculate valid spawn positions to reduce runtime calculations
        precomputedPositions.removeAll()
        
        // Use dynamic spawn area based on actual screen size
        let spawnArea = GameConstants.getSpawnArea(screenWidth: screenSize.width, screenHeight: screenSize.height)
        let xRange = spawnArea.x
        let yRange = spawnArea.y
        
        // Generate a grid of potential positions
        let gridSpacing: Double = 35.0
        
        var x = xRange.lowerBound
        while x <= xRange.upperBound {
            var y = yRange.lowerBound
            while y <= yRange.upperBound {
                let position = CGPoint(x: x, y: y)
                precomputedPositions.append(position)
                y += gridSpacing
            }
            x += gridSpacing
        }
        
        // Shuffle to randomize
        precomputedPositions.shuffle()
        positionIndex = 0
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
        
        let (balloon, spawnPosition) = BalloonSpawner.createBalloon(
            level: currentLevel,
            isPositive: shouldSpawnPositive,
            precomputedPositions: precomputedPositions,
            positionIndex: &positionIndex,
            recentPositions: recentSpawnPositions,
            minDistance: minSpawnDistance
        )
        
        // Track this spawn position
        recentSpawnPositions.append(spawnPosition)
        
        // Update spawn counters
        if balloon.isPositive {
            positiveSpawned += balloon.points
        } else {
            negativeSpawned += balloon.points
        }
        
        // Simple, direct balloon creation
        balloons.append(balloon)
        
        // Schedule removal
        let lifetime = LevelConfiguration.balloonLifetime(for: currentLevel)
        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
            self.removeBalloon(balloon)
        }
    }
    
    private func triggerColorSplash(at position: CGPoint, color: Color) {
        let splash = ColorSplash(position: position, color: color)
        colorSplashes.append(splash)
        
        // Remove splash after animation completes (longer for paint effect)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.colorSplashes.removeAll { $0.id == splash.id }
        }
    }
    
    private func triggerPopAnimation(at position: CGPoint, color: Color, isPositive: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Remove oldest effects if we have too many (prevents memory buildup)
            if self.popEffects.count >= self.maxPopEffects {
                let oldestIds = Array(self.popEffects.prefix(self.popEffects.count - self.maxPopEffects + 1).map { $0.id })
                self.popEffects.removeAll { oldestIds.contains($0.id) }
            }
            
            let effect = PopEffect(position: position, color: color, isPositive: isPositive)
            self.popEffects.append(effect)
            
            // Performance-adjusted cleanup duration - moved to background
            let cleanupDelay = PerformanceDetector.shared.enableComplexAnimations ? 0.8 : 0.5
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + cleanupDelay) {
                DispatchQueue.main.async {
                    self.popEffects.removeAll { $0.id == effect.id }
                }
            }
        }
    }
    
    private func removeBalloon(_ balloon: GameBalloon) {
        balloons.removeAll { $0.id == balloon.id }
        
        // Clean up spawn positions  
        cleanupOldSpawnPositions()
    }
    
    private func cleanupOldSpawnPositions() {
        // Keep only the most recent 8 spawn positions to avoid too much clustering
        if recentSpawnPositions.count > 8 {
            recentSpawnPositions = Array(recentSpawnPositions.suffix(8))
        }
    }
    
    private func completeLevel() {
        gameActive = false
        mainGameTimer?.invalidate()
        balloons = []
        levelComplete = true
        
        // Play level complete sound
        SoundManager.shared.playLevelComplete()
        
        // Calculate star rating
        starRating = LevelConfiguration.getStarRating(balloonsPopped: currentLevelStats.totalBalloonsPopped, for: currentLevel)
        currentLevelStats.starRating = starRating
        currentLevelStats.calculateStarRating(for: currentLevel, pointsEarned: score)
        
        showLevelUp = true
        
        // Delay setting gameResult so overlay can show first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.gameResult = .completed
        }
    }
    
    private func failLevel() {
        gameActive = false
        mainGameTimer?.invalidate()
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
        initialTimeLimit = timeRemaining
        levelComplete = false
        showLevelUp = false
        showFailure = false
        failureMessage = ""
        gameResult = nil
        mainGameTimer?.invalidate()
        spawnTimer?.invalidate()
        timeAdjustmentTimer?.invalidate()
        currentLevelStats = GameStatistics()
        starRating = 0
        timeAdjustment = 0
        
        // Simple reset
        
        // Clear all effects to prevent memory leaks
        popEffects.removeAll()
        colorSplashes.removeAll()
        recentSpawnPositions.removeAll()
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
    
    static func createBalloon(level: Int, isPositive: Bool, precomputedPositions: [CGPoint], positionIndex: inout Int, recentPositions: [CGPoint] = [], minDistance: Double = 50.0) -> (GameBalloon, CGPoint) {
        let pointRange = LevelConfiguration.pointRange(for: level, isPositive: isPositive)
        let points = Int.random(in: pointRange)
        
        // Use precomputed position with simple cycling and distance check
        var position = CGPoint.zero
        var attempts = 0
        let maxAttempts = 10  // Reduced attempts
        
        repeat {
            // Get next precomputed position
            if !precomputedPositions.isEmpty {
                position = precomputedPositions[positionIndex % precomputedPositions.count]
                positionIndex = (positionIndex + 1) % precomputedPositions.count
            } else {
                // Fallback to simple random if no precomputed positions
                position = CGPoint(
                    x: Double.random(in: GameConstants.balloonSpawnArea.x),
                    y: Double.random(in: GameConstants.balloonSpawnArea.y)
                )
            }
            attempts += 1
            
            // Quick distance check - exit early if too many attempts
            let tooClose = recentPositions.contains { recentPos in
                let dx = position.x - recentPos.x
                let dy = position.y - recentPos.y
                return (dx * dx + dy * dy) < (minDistance * minDistance)  // Avoid sqrt
            }
            
            if !tooClose || attempts >= maxAttempts {
                break
            }
        } while true
        
        let colorIndex = Int.random(in: 0..<GameConstants.balloonColors.count)
        let balloon = GameBalloon(
            x: position.x,
            y: position.y,
            isPositive: isPositive,
            points: points,
            colorIndex: colorIndex
        )
        
        return (balloon, position)
    }
}