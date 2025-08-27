// MARK: - ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    
    var body: some View {
        switch gameState.currentScreen {
        case .home:
            HomeScreenView()
                .environmentObject(gameState)
        case .game:
            GameView()
                .environmentObject(gameState)
        }
    }
}
