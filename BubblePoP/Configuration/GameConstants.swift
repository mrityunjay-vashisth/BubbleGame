// MARK: - GameConstants.swift
import SwiftUI

struct GameConstants {
    static let maxLevels = 50
    static let maxFailuresBeforePenalty = 3
    
    // UI Constants
    static let levelBoxSize: CGFloat = 80
    static let balloonSize = CGSize(width: 60, height: 75)
    static let levelGridColumns = 4
    
    // Animation Durations
    static let popAnimationDuration: Double = 1.5
    static let levelUpAnimationDuration: Double = 0.6
    static let balloonSpawnDuration: Double = 0.4
    
    // Colors
    static let balloonColors: [Color] = [
        Color(red: 0.9, green: 0.3, blue: 0.4),  // Coral
        Color(red: 0.2, green: 0.7, blue: 0.9),  // Sky blue
        Color(red: 0.8, green: 0.6, blue: 0.9),  // Lavender
        Color(red: 0.3, green: 0.8, blue: 0.6),  // Mint
        Color(red: 0.9, green: 0.7, blue: 0.3),  // Gold
        Color(red: 0.6, green: 0.4, blue: 0.8),  // Purple
        Color(red: 0.9, green: 0.5, blue: 0.2)   // Orange
    ]
    
    // Spawn Areas
    static let balloonSpawnArea = (
        x: 60.0...340.0,
        y: 180.0...500.0
    )
    
    // Background Gradients
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.1, blue: 0.2),
            Color(red: 0.1, green: 0.15, blue: 0.3),
            Color(red: 0.15, green: 0.25, blue: 0.4)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let waterGradient = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.8),
            Color(red: 0.1, green: 0.8, blue: 1.0).opacity(0.6),
            Color(red: 0.0, green: 0.9, blue: 0.9).opacity(0.9)
        ],
        startPoint: .bottom,
        endPoint: .top
    )
}
