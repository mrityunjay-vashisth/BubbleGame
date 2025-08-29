// MARK: - GameConstants.swift
import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Performance Detection
struct PerformanceDetector {
    static let shared = PerformanceDetector()
    
    private let isHighPerformanceDevice: Bool
    private let isLowMemoryDevice: Bool
    
    private init() {
        #if os(iOS)
        let deviceModel = UIDevice.current.model
        let systemVersion = Float(UIDevice.current.systemVersion) ?? 0.0
        
        // Detect iPhone 12, 13, 14, 15 and newer as high performance
        // Older devices or devices with less than iOS 14 are considered lower performance
        isHighPerformanceDevice = systemVersion >= 14.0 && 
            (deviceModel.contains("iPhone") && !deviceModel.contains("SE"))
        
        isLowMemoryDevice = ProcessInfo.processInfo.physicalMemory < 3_000_000_000 // Less than 3GB RAM
        #else
        isHighPerformanceDevice = true
        isLowMemoryDevice = false
        #endif
    }
    
    // Performance-based settings
    var maxConcurrentBalloons: Int {
        return isHighPerformanceDevice ? 12 : 8
    }
    
    var maxConcurrentEffects: Int {
        return isHighPerformanceDevice ? 10 : 6
    }
    
    var backgroundBubbleCount: Int {
        return isHighPerformanceDevice ? 6 : 3
    }
    
    var timerInterval: TimeInterval {
        return isHighPerformanceDevice ? 0.033 : 0.050  // 30fps vs 20fps
    }
    
    var enableComplexAnimations: Bool {
        return isHighPerformanceDevice && !isLowMemoryDevice
    }
    
    var animationDurationMultiplier: Double {
        return isHighPerformanceDevice ? 1.0 : 1.3  // Slower animations on older devices
    }
    
    var enableViewRecycling: Bool {
        // Enable view recycling on lower-end devices to reduce allocation overhead
        return !isHighPerformanceDevice || isLowMemoryDevice
    }
    
    // Metal framework support detection
    var supportsMetalEffects: Bool {
        #if targetEnvironment(simulator)
        return false // Simulators often have Metal issues
        #else
        return isHighPerformanceDevice && !isLowMemoryDevice
        #endif
    }
    
    var enableBlurEffects: Bool {
        return supportsMetalEffects
    }
    
    var enableShadowEffects: Bool {
        return supportsMetalEffects
    }
    
    var enableAdvancedMaterials: Bool {
        return supportsMetalEffects
    }
}

struct GameConstants {
    static let maxLevels = 50
    static let maxFailuresBeforePenalty = 3
    
    // UI Constants
    static let levelBoxSize: CGFloat = 84
    static let balloonSize = CGSize(width: 70, height: 85)  // Made bigger: was 60x75, now 70x85
    static let levelGridColumns = 4
    
    // Performance-adjusted Animation Durations
    static let popAnimationDuration: Double = 1.0 * PerformanceDetector.shared.animationDurationMultiplier
    static let levelUpAnimationDuration: Double = 0.6 * PerformanceDetector.shared.animationDurationMultiplier
    static let balloonSpawnDuration: Double = 0.4 * PerformanceDetector.shared.animationDurationMultiplier
    
    // Modern Design System
    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 20
    static let elementSpacing: CGFloat = 16
    
    // Cached color palette for performance - created once and reused
    static let balloonColors: [Color] = {
        return [
            Color(red: 1.0, green: 0.65, blue: 0.4),    // Warm Orange
            Color(red: 0.95, green: 0.55, blue: 0.35),  // Coral
            Color(red: 0.4, green: 0.75, blue: 0.6),    // Fresh Green  
            Color(red: 0.3, green: 0.7, blue: 0.9),     // Sky Blue
            Color(red: 0.85, green: 0.45, blue: 0.65),  // Rose Pink
            Color(red: 0.9, green: 0.7, blue: 0.3),     // Golden Yellow
            Color(red: 0.6, green: 0.45, blue: 0.85)    // Purple
        ]
    }()
    
    // Cached UI Colors for performance - created once and reused
    struct UI {
        // Warm Light Foundation - cached for performance
        static let background = Color(red: 0.98, green: 0.97, blue: 0.95)      // Warm Off-White
        static let surface = Color(red: 1.0, green: 0.995, blue: 0.99)        // Soft White
        static let surfaceElevated = Color(red: 1.0, green: 1.0, blue: 1.0)   // Pure White
        
        // Rich Text Hierarchy - cached for performance
        static let primaryText = Color(red: 0.2, green: 0.2, blue: 0.25)       // Rich Dark
        static let secondaryText = Color(red: 0.5, green: 0.5, blue: 0.55)     // Warm Gray
        static let tertiaryText = Color(red: 0.7, green: 0.7, blue: 0.75)      // Light Gray
        
        // Vibrant Accent Colors - cached for performance
        static let accent = Color(red: 1.0, green: 0.65, blue: 0.4)            // Warm Orange
        static let success = Color(red: 0.4, green: 0.75, blue: 0.6)           // Fresh Green
        static let warning = Color(red: 0.9, green: 0.7, blue: 0.3)            // Golden
        static let danger = Color(red: 0.95, green: 0.55, blue: 0.35)          // Coral Red
        
        // Modern Material Effects
        static let glassMaterial = Material.ultraThinMaterial
        static let cardMaterial = Material.thinMaterial
        
        // Warm Borders and Dividers - cached for performance
        static let border = Color(red: 0.92, green: 0.91, blue: 0.89)
        static let divider = Color(red: 0.96, green: 0.95, blue: 0.93)
    }
    
    // Spawn Areas - Keep balloons in the center playable area
    // These are safe defaults - actual spawn area should be calculated based on screen size
    static let balloonSpawnArea = (
        x: 30.0...370.0,    // Horizontal range with safe margins
        y: 230.0...470.0    // Vertical range avoiding UI elements (header + stats + controls)
    )
    
    // Dynamic spawn area calculation based on screen size
    static func getSpawnArea(screenWidth: CGFloat, screenHeight: CGFloat) -> (x: ClosedRange<Double>, y: ClosedRange<Double>) {
        let headerHeight: CGFloat = 80   // Back button and level indicator
        let statsHeight: CGFloat = 120   // Score and timer stats board
        let controlsHeight: CGFloat = 180  // Controls + padding
        let horizontalMargin: CGFloat = 30
        let verticalPadding: CGFloat = 30  // Extra padding around UI elements
        
        let minX = horizontalMargin
        let maxX = screenWidth - horizontalMargin
        let minY = headerHeight + statsHeight + verticalPadding  // Clear both header AND stats
        let maxY = screenHeight - controlsHeight - verticalPadding  // Clear controls
        
        return (
            x: Double(minX)...Double(maxX),
            y: Double(minY)...Double(maxY)
        )
    }
    
    // Cached gradients for performance - created once and reused
    static let backgroundGradient: LinearGradient = {
        return LinearGradient(
            colors: [
                Color(red: 0.99, green: 0.98, blue: 0.96),  // Warm white top
                UI.background,
                Color(red: 0.97, green: 0.96, blue: 0.94)   // Slightly warmer bottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }()
    
    static let waterGradient: LinearGradient = {
        return LinearGradient(
            colors: [
                UI.accent.opacity(0.4),
                UI.success.opacity(0.3),
                Color(red: 0.3, green: 0.7, blue: 0.9).opacity(0.5)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }()
    
    // Cached shadow colors for performance
    static let cardShadow = Color.black.opacity(0.08)
    static let subtleShadow = Color.black.opacity(0.04)
    static let accentShadow = UI.accent.opacity(0.15)
}
