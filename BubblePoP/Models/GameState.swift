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
        print("🎉 Level \(level) completed! Unlocking level \(level + 1)")
        DispatchQueue.main.async {
            self.completedLevels.insert(level)
            
            // Unlock next level if not already unlocked
            if level < 50 {
                self.unlockedLevels.insert(level + 1)
                print("✅ Level \(level + 1) now unlocked. Total unlocked: \(self.unlockedLevels.sorted())")
            }
            
            // Reset failure count
            self.levelFailures[level] = 0
            
            // Force UI update by recreating the set
            self.unlockedLevels = Set(self.unlockedLevels)
            self.completedLevels = Set(self.completedLevels)
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
