// MARK: - GameBalloon.swift
import SwiftUI

struct GameBalloon: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let isPositive: Bool
    let points: Int
    let color: Color
}
