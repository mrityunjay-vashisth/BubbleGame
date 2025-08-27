// MARK: - GameConstants.swift
import SwiftUI

struct GameConstants {
    static let maxLevels = 50
    static let maxFailuresBeforePenalty = 3
    
    // UI Constants
    static let levelBoxSize: CGFloat = 84
    static let balloonSize = CGSize(width: 70, height: 85)  // Made bigger: was 60x75, now 70x85
    static let levelGridColumns = 4
    
    // Animation Durations
    static let popAnimationDuration: Double = 1.5
    static let levelUpAnimationDuration: Double = 0.6
    static let balloonSpawnDuration: Double = 0.4
    
    // Modern Design System
    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 20
    static let elementSpacing: CGFloat = 16
    
    // Warm & Vibrant Modern Color Palette - Inspired by Fitness/Wellness Apps
    static let balloonColors: [Color] = [
        Color(red: 1.0, green: 0.65, blue: 0.4),    // Warm Orange
        Color(red: 0.95, green: 0.55, blue: 0.35),  // Coral
        Color(red: 0.4, green: 0.75, blue: 0.6),    // Fresh Green  
        Color(red: 0.3, green: 0.7, blue: 0.9),     // Sky Blue
        Color(red: 0.85, green: 0.45, blue: 0.65),  // Rose Pink
        Color(red: 0.9, green: 0.7, blue: 0.3),     // Golden Yellow
        Color(red: 0.6, green: 0.45, blue: 0.85)    // Purple
    ]
    
    // Warm & Modern UI Colors - Wellness App Inspired
    struct UI {
        // Warm Light Foundation
        static let background = Color(red: 0.98, green: 0.97, blue: 0.95)      // Warm Off-White
        static let surface = Color(red: 1.0, green: 0.995, blue: 0.99)        // Soft White
        static let surfaceElevated = Color(red: 1.0, green: 1.0, blue: 1.0)   // Pure White
        
        // Rich Text Hierarchy
        static let primaryText = Color(red: 0.2, green: 0.2, blue: 0.25)       // Rich Dark
        static let secondaryText = Color(red: 0.5, green: 0.5, blue: 0.55)     // Warm Gray
        static let tertiaryText = Color(red: 0.7, green: 0.7, blue: 0.75)      // Light Gray
        
        // Vibrant Accent Colors
        static let accent = Color(red: 1.0, green: 0.65, blue: 0.4)            // Warm Orange
        static let success = Color(red: 0.4, green: 0.75, blue: 0.6)           // Fresh Green
        static let warning = Color(red: 0.9, green: 0.7, blue: 0.3)            // Golden
        static let danger = Color(red: 0.95, green: 0.55, blue: 0.35)          // Coral Red
        
        // Modern Material Effects
        static let glassMaterial = Material.ultraThinMaterial
        static let cardMaterial = Material.thinMaterial
        
        // Warm Borders and Dividers
        static let border = Color(red: 0.92, green: 0.91, blue: 0.89)
        static let divider = Color(red: 0.96, green: 0.95, blue: 0.93)
    }
    
    // Spawn Areas - Use full vertical space for better distribution
    static let balloonSpawnArea = (
        x: 60.0...340.0,    // Safe horizontal margins
        y: 180.0...520.0    // Expanded: from stats area to just above controls
    )
    
    // Warm & Inviting Gradients
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.99, green: 0.98, blue: 0.96),  // Warm white top
            UI.background,
            Color(red: 0.97, green: 0.96, blue: 0.94)   // Slightly warmer bottom
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let waterGradient = LinearGradient(
        colors: [
            UI.accent.opacity(0.4),
            UI.success.opacity(0.3),
            Color(red: 0.3, green: 0.7, blue: 0.9).opacity(0.5)
        ],
        startPoint: .bottom,
        endPoint: .top
    )
    
    // Warm, Soft Shadows
    static let cardShadow = Color.black.opacity(0.08)
    static let subtleShadow = Color.black.opacity(0.04)
    static let accentShadow = UI.accent.opacity(0.15)
}
