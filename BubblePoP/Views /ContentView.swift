// MARK: - ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    
    var body: some View {
        ZStack {
            // Modern Background
            GameConstants.backgroundGradient
                .ignoresSafeArea()
            
            // Fast, clean screen transitions
            switch gameState.currentScreen {
            case .home:
                HomeScreenView()
                    .environmentObject(gameState)
                    .transition(.opacity)
            case .game:
                GameView()
                    .environmentObject(gameState)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: gameState.currentScreen)
    }
}
