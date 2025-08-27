// MARK: - ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    
    var body: some View {
        ZStack {
            // Modern Background
            GameConstants.backgroundGradient
                .ignoresSafeArea()
            
            // Smooth Screen Transitions
            switch gameState.currentScreen {
            case .home:
                HomeScreenView()
                    .environmentObject(gameState)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            case .game:
                GameView()
                    .environmentObject(gameState)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: gameState.currentScreen)
    }
}
