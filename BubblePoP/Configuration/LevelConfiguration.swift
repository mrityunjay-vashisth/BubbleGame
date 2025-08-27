// MARK: - LevelConfiguration.swift
import Foundation

struct LevelConfiguration {
    static func pointsNeeded(for level: Int) -> Int {
        switch level {
        case 1: return 10
        case 2: return 25
        case 3: return 45
        case 4: return 70
        case 5: return 100
        default: return 100 + (level - 5) * 30
        }
    }
    
    static func timeAllowed(for level: Int) -> Int {
        switch level {
        case 1: return 30
        case 2: return 45
        case 3: return 60
        case 4: return 75
        default: return 90
        }
    }
    
    static func spawnInterval(for level: Int) -> Double {
        max(0.2, 0.4 - (Double(level - 1) * 0.02))
    }
    
    static func balloonLifetime(for level: Int) -> Double {
        let baseLifetime = max(2.5, 4.5 - (Double(level - 1) * 0.2))
        return Double.random(in: baseLifetime...(baseLifetime + 1.0))
    }
    
    static func pointRange(for level: Int, isPositive: Bool) -> ClosedRange<Int> {
        if isPositive {
            return level <= 3 ? 1...2 : 1...3
        } else {
            return level <= 2 ? 1...1 : 1...2
        }
    }
    
    static func positiveBias(for level: Int) -> Double {
        max(0.5, 0.8 - (Double(level) * 0.05))
    }
}
