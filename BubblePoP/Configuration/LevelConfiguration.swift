// MARK: - LevelConfiguration.swift
import Foundation

struct LevelConfiguration {
    // Pre-computed lookup tables for better performance
    private static let pointsLookup: [Int: Int] = {
        var lookup = [Int: Int]()
        for level in 1...50 {
            switch level {
            case 1: lookup[level] = 10
            case 2: lookup[level] = 25
            case 3: lookup[level] = 45
            case 4: lookup[level] = 70
            case 5: lookup[level] = 100
            default: lookup[level] = 100 + (level - 5) * 30
            }
        }
        return lookup
    }()
    
    private static let timeLookup: [Int: Int] = {
        var lookup = [Int: Int]()
        for level in 1...50 {
            switch level {
            case 1: lookup[level] = 30
            case 2: lookup[level] = 45
            case 3: lookup[level] = 60
            case 4: lookup[level] = 75
            default: lookup[level] = 90
            }
        }
        return lookup
    }()
    static func pointsNeeded(for level: Int) -> Int {
        return pointsLookup[level] ?? (100 + (level - 5) * 30)
    }
    
    static func timeAllowed(for level: Int) -> Int {
        return timeLookup[level] ?? 90
    }
    
    static func spawnInterval(for level: Int) -> Double {
        // Pre-calculate to avoid repeated floating point operations
        let interval = 0.4 - (Double(level - 1) * 0.02)
        return interval > 0.2 ? interval : 0.2
    }
    
    static func balloonLifetime(for level: Int) -> Double {
        let baseLifetime = max(2.5, 4.5 - (Double(level - 1) * 0.2))
        return Double.random(in: baseLifetime...(baseLifetime + 1.0))
    }
    
    static func pointRange(for level: Int, isPositive: Bool) -> ClosedRange<Int> {
        if isPositive {
            // Positive balloons: 1 to level (NO LIMITS! CHAOS!)
            return 1...level
        } else {
            // Negative balloons: 1 to level (MAXIMUM CHAOS!)
            return 1...level
        }
    }
    
    static func positiveBias(for level: Int) -> Double {
        max(0.5, 0.8 - (Double(level) * 0.05))
    }
}
