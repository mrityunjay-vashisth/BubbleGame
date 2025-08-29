// MARK: - GameState.swift
import Foundation
import SwiftUI

// MARK: - Persistence Manager
class GameStatePersistence {
    private static let unlockedLevelsKey = "UnlockedLevels"
    private static let completedLevelsKey = "CompletedLevels"
    private static let levelFailuresKey = "LevelFailures"
    private static let selectedLevelKey = "SelectedLevel"
    private static let levelStarsKey = "LevelStars"
    
    static func save(gameState: GameState) {
        let defaults = UserDefaults.standard
        
        // Save as arrays for UserDefaults compatibility
        defaults.set(Array(gameState.unlockedLevels), forKey: unlockedLevelsKey)
        defaults.set(Array(gameState.completedLevels), forKey: completedLevelsKey)
        
        // Convert [Int: Int] dictionary to [String: Int] for UserDefaults compatibility
        let levelFailuresForStorage = gameState.levelFailures.reduce(into: [String: Int]()) { result, pair in
            result[String(pair.key)] = pair.value
        }
        defaults.set(levelFailuresForStorage, forKey: levelFailuresKey)
        defaults.set(gameState.selectedLevel, forKey: selectedLevelKey)
        
        // Save star ratings
        let levelStarsForStorage = gameState.levelStars.reduce(into: [String: Int]()) { result, pair in
            result[String(pair.key)] = pair.value
        }
        defaults.set(levelStarsForStorage, forKey: levelStarsKey)
    }
    
    static func load() -> (unlockedLevels: Set<Int>, completedLevels: Set<Int>, levelFailures: [Int: Int], selectedLevel: Int, levelStars: [Int: Int]) {
        let defaults = UserDefaults.standard
        
        let unlockedArray = defaults.array(forKey: unlockedLevelsKey) as? [Int] ?? [1]
        let completedArray = defaults.array(forKey: completedLevelsKey) as? [Int] ?? []
        
        // Convert [String: Int] back to [Int: Int]
        let storedFailures = defaults.dictionary(forKey: levelFailuresKey) as? [String: Int] ?? [:]
        let failures = storedFailures.reduce(into: [Int: Int]()) { result, pair in
            if let key = Int(pair.key) {
                result[key] = pair.value
            }
        }
        
        // Load star ratings
        let storedStars = defaults.dictionary(forKey: levelStarsKey) as? [String: Int] ?? [:]
        let stars = storedStars.reduce(into: [Int: Int]()) { result, pair in
            if let key = Int(pair.key) {
                result[key] = pair.value
            }
        }
        
        let selected = defaults.integer(forKey: selectedLevelKey)
        
        return (
            unlockedLevels: Set(unlockedArray),
            completedLevels: Set(completedArray),
            levelFailures: failures,
            selectedLevel: selected > 0 ? selected : 1,
            levelStars: stars
        )
    }
}

enum GameScreen {
    case home
    case game
}

class GameState: ObservableObject {
    @Published var currentScreen: GameScreen = .home
    @Published var unlockedLevels: Set<Int> = [1]
    @Published var completedLevels: Set<Int> = []
    @Published var levelFailures: [Int: Int] = [:]
    @Published var selectedLevel = 1
    @Published var levelStars: [Int: Int] = [:]
    @Published var levelStatistics = LevelStatistics()
    
    init() {
        loadGameState()
    }
    
    var highestUnlockedLevel: Int {
        unlockedLevels.max() ?? 1
    }
    
    func completeLevel(_ level: Int, stars: Int = 1, stats: GameStatistics? = nil) {
        DispatchQueue.main.async {
            self.completedLevels.insert(level)
            
            // Update star rating (keep best)
            let currentStars = self.levelStars[level] ?? 0
            if stars > currentStars {
                self.levelStars[level] = stars
            }
            
            // Save statistics if provided
            if let stats = stats {
                self.levelStatistics.recordLevelCompletion(level: level, stats: stats)
            }
            
            // Unlock next level if not already unlocked
            if level < 50 {
                self.unlockedLevels.insert(level + 1)
            }
            
            // Reset failure count
            self.levelFailures[level] = 0
            
            // Force UI update by recreating the set
            self.unlockedLevels = Set(self.unlockedLevels)
            self.completedLevels = Set(self.completedLevels)
            
            // Save progress
            self.saveGameState()
        }
    }
    
    func failLevel(_ level: Int) {
        let failures = (levelFailures[level] ?? 0) + 1
        levelFailures[level] = failures
        
        // Apply penalty after 3 failures
        if failures >= 3 && level > 1 {
            let levelToLock = level - 1
            unlockedLevels.remove(levelToLock)
            completedLevels.remove(levelToLock)
            
            // Reset failure count
            levelFailures[level] = 0
            
            // Adjust selected level if needed
            if !unlockedLevels.contains(selectedLevel) {
                selectedLevel = unlockedLevels.max() ?? 1
            }
        }
        
        // Save progress
        saveGameState()
    }
    
    func selectLevel(_ level: Int) {
        guard unlockedLevels.contains(level) else { return }
        selectedLevel = level
        currentScreen = .game
        saveGameState() // Save selected level
    }
    
    func goHome() {
        currentScreen = .home
    }
    
    // MARK: - Persistence Methods
    private func saveGameState() {
        GameStatePersistence.save(gameState: self)
    }
    
    private func loadGameState() {
        let saved = GameStatePersistence.load()
        self.unlockedLevels = saved.unlockedLevels
        self.completedLevels = saved.completedLevels
        self.levelFailures = saved.levelFailures
        self.selectedLevel = saved.selectedLevel
        self.levelStars = saved.levelStars
    }
    
    func getStarsForLevel(_ level: Int) -> Int {
        return levelStars[level] ?? 0
    }
}
