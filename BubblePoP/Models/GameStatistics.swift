import Foundation

struct GameStatistics {
    var totalBalloonsPopped: Int = 0
    var positiveBalloonsPopped: Int = 0
    var negativeBalloonsPopped: Int = 0
    var starRating: Int = 0
    var efficiency: Double = 0.0
    
    init() {}
    
    init(totalPopped: Int, positivePopped: Int, negativePopped: Int) {
        self.totalBalloonsPopped = totalPopped
        self.positiveBalloonsPopped = positivePopped
        self.negativeBalloonsPopped = negativePopped
    }
    
    mutating func calculateStarRating(for level: Int, pointsEarned: Int) {
        let optimalBalloons = GameStatistics.calculateOptimalBalloons(for: level, pointsNeeded: pointsEarned)
        let efficiency = Double(optimalBalloons) / Double(totalBalloonsPopped)
        self.efficiency = efficiency * 100
        
        if totalBalloonsPopped <= optimalBalloons {
            starRating = 3
        } else if totalBalloonsPopped <= Int(Double(optimalBalloons) * 1.5) {
            starRating = 2
        } else {
            starRating = 1
        }
    }
    
    static func calculateOptimalBalloons(for level: Int, pointsNeeded: Int) -> Int {
        let maxPointsPerBalloon = level
        let minBalloonsNeeded = Int(ceil(Double(pointsNeeded) / Double(maxPointsPerBalloon)))
        return minBalloonsNeeded + 2
    }
    
    func getEfficiencyMessage() -> String {
        switch starRating {
        case 3:
            return "Perfect! Maximum efficiency!"
        case 2:
            return "Good job! Can be more efficient."
        case 1:
            return "Level complete! Try using fewer balloons."
        default:
            return ""
        }
    }
}

class LevelStatistics: ObservableObject {
    @Published var levelStats: [Int: GameStatistics] = [:]
    @Published var lifetimeBalloonsPopped: Int = 0
    @Published var lifetimePositivePopped: Int = 0
    @Published var lifetimeNegativePopped: Int = 0
    
    private static let levelStatsKey = "LevelStatistics"
    private static let lifetimeStatsKey = "LifetimeStatistics"
    
    init() {
        loadStatistics()
    }
    
    func recordLevelCompletion(level: Int, stats: GameStatistics) {
        levelStats[level] = stats
        
        lifetimeBalloonsPopped += stats.totalBalloonsPopped
        lifetimePositivePopped += stats.positiveBalloonsPopped
        lifetimeNegativePopped += stats.negativeBalloonsPopped
        
        saveStatistics()
    }
    
    func getStarsForLevel(_ level: Int) -> Int {
        return levelStats[level]?.starRating ?? 0
    }
    
    private func saveStatistics() {
        let defaults = UserDefaults.standard
        
        var levelStatsData: [String: [String: Any]] = [:]
        for (level, stats) in levelStats {
            levelStatsData[String(level)] = [
                "total": stats.totalBalloonsPopped,
                "positive": stats.positiveBalloonsPopped,
                "negative": stats.negativeBalloonsPopped,
                "stars": stats.starRating,
                "efficiency": stats.efficiency
            ]
        }
        
        defaults.set(levelStatsData, forKey: LevelStatistics.levelStatsKey)
        
        let lifetimeData: [String: Int] = [
            "total": lifetimeBalloonsPopped,
            "positive": lifetimePositivePopped,
            "negative": lifetimeNegativePopped
        ]
        defaults.set(lifetimeData, forKey: LevelStatistics.lifetimeStatsKey)
    }
    
    private func loadStatistics() {
        let defaults = UserDefaults.standard
        
        if let levelStatsData = defaults.dictionary(forKey: LevelStatistics.levelStatsKey) as? [String: [String: Any]] {
            for (levelStr, statsDict) in levelStatsData {
                if let level = Int(levelStr),
                   let total = statsDict["total"] as? Int,
                   let positive = statsDict["positive"] as? Int,
                   let negative = statsDict["negative"] as? Int,
                   let stars = statsDict["stars"] as? Int,
                   let efficiency = statsDict["efficiency"] as? Double {
                    
                    var stats = GameStatistics(totalPopped: total, positivePopped: positive, negativePopped: negative)
                    stats.starRating = stars
                    stats.efficiency = efficiency
                    levelStats[level] = stats
                }
            }
        }
        
        if let lifetimeData = defaults.dictionary(forKey: LevelStatistics.lifetimeStatsKey) as? [String: Int] {
            lifetimeBalloonsPopped = lifetimeData["total"] ?? 0
            lifetimePositivePopped = lifetimeData["positive"] ?? 0
            lifetimeNegativePopped = lifetimeData["negative"] ?? 0
        }
    }
}