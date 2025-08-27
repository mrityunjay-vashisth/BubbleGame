// MARK: - GameState.swift
import Foundation

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
    
    var highestUnlockedLevel: Int {
        unlockedLevels.max() ?? 1
    }
    
    func completeLevel(_ level: Int) {
        completedLevels.insert(level)
        
        // Unlock next level if not already unlocked
        if level < 50 {
            unlockedLevels.insert(level + 1)
        }
        
        // Reset failure count
        levelFailures[level] = 0
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
    }
    
    func selectLevel(_ level: Int) {
        guard unlockedLevels.contains(level) else { return }
        selectedLevel = level
        currentScreen = .game
    }
    
    func goHome() {
        currentScreen = .home
    }
}
