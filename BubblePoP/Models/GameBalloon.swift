// MARK: - GameBalloon.swift
import SwiftUI

struct GameBalloon: Identifiable, Hashable {
    let id: Int  // Use Int instead of UUID for better performance
    let x: CGFloat  // Use CGFloat for SwiftUI compatibility
    let y: CGFloat
    let isPositive: Bool
    let points: Int  // Keep as Int for SwiftUI compatibility
    let colorIndex: Int  // Store color index instead of Color object
    
    // Computed property for color to maintain API compatibility
    var color: Color {
        let colors = GameConstants.balloonColors
        let index = colorIndex % colors.count
        return colors[index]
    }
    
    // Static counter for efficient ID generation
    private static var nextID: Int = 0
    
    init(x: Double, y: Double, isPositive: Bool, points: Int, colorIndex: Int) {
        GameBalloon.nextID += 1
        self.id = GameBalloon.nextID
        self.x = CGFloat(x)
        self.y = CGFloat(y)
        self.isPositive = isPositive
        self.points = max(0, points)
        self.colorIndex = colorIndex % GameConstants.balloonColors.count
    }
    
    // Hashable conformance for efficient Set operations
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GameBalloon, rhs: GameBalloon) -> Bool {
        return lhs.id == rhs.id
    }
}
