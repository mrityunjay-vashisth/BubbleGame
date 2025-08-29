import SwiftUI

struct GameOverlaysView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        ZStack {
            if gameManager.showLevelUp {
                LevelCompleteOverlay()
                    .environmentObject(gameState)
                    .environmentObject(gameManager)
                    .transition(.scale.combined(with: .opacity))
            }
            
            if gameManager.showFailure {
                LevelFailedOverlay()
                    .environmentObject(gameState)
                    .environmentObject(gameManager)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct LevelCompleteOverlay: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var gameManager: GameManager
    @State private var showConfetti = false
    @State private var scale = 0.5
    @State private var rotation = -180.0
    @State private var starsScale = 0.0
    
    var starColors: [Color] {
        switch gameManager.starRating {
        case 3: return [.yellow, .orange]
        case 2: return [.gray.opacity(0.8), .gray.opacity(0.6)]
        case 1: return [.brown.opacity(0.8), .brown.opacity(0.6)]
        default: return [.gray, .gray.opacity(0.5)]
        }
    }
    
    var efficiencyMessage: String {
        let thresholds = LevelConfiguration.getStarThresholds(for: gameState.selectedLevel)
        switch gameManager.starRating {
        case 3: return "Perfect! Maximum efficiency!"
        case 2: return "Good job! Target: ≤\(thresholds.threeStars) balloons"
        case 1: return "Complete! Target: ≤\(thresholds.threeStars) balloons"
        default: return ""
        }
    }
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .blur(radius: 3)
            
            // Confetti only for 3 stars
            if showConfetti && gameManager.starRating == 3 {
                ConfettiView()
            }
            
            VStack(spacing: 16) {
                // Trophy animation for 3 stars, simple icon for less
                if gameManager.starRating == 3 {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)
                }
                
                Text("LEVEL COMPLETE!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gameManager.starRating == 3 ? [.yellow, .orange, .pink] : [.white, .gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 5)
                
                // Star Rating Display
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { star in
                        Image(systemName: star <= gameManager.starRating ? "star.fill" : "star")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                star <= gameManager.starRating ?
                                LinearGradient(colors: starColors, startPoint: .top, endPoint: .bottom) :
                                LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                            )
                            .scaleEffect(starsScale)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.6)
                                .delay(Double(star) * 0.1),
                                value: starsScale
                            )
                    }
                }
                .padding(.vertical, 8)
                
                // Statistics Display
                VStack(spacing: 12) {
                    Text("Score: \(gameManager.score)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "circle.grid.3x3.fill")
                                .foregroundColor(.blue)
                            Text("Balloons Popped: \(gameManager.currentLevelStats.totalBalloonsPopped)")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        HStack(spacing: 20) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(gameManager.currentLevelStats.positiveBalloonsPopped)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("\(gameManager.currentLevelStats.negativeBalloonsPopped)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    
                    Text(efficiencyMessage)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(gameManager.starRating == 3 ? .yellow : .white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                HStack(spacing: 16) {
                    if gameManager.starRating < 3 {
                        Button(action: {
                            gameManager.retryLevel()
                        }) {
                            Text("Retry")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 120)
                                .padding()
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .cyan],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(color: .blue.opacity(0.5), radius: 10)
                        }
                    }
                    
                    Button(action: {
                        gameState.completeLevel(gameState.selectedLevel, stars: gameManager.starRating, stats: gameManager.currentLevelStats)
                        gameState.goHome()
                    }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 120)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: .green.opacity(0.5), radius: 10)
                    }
                }
                .scaleEffect(scale)
            }
            .padding(GameConstants.cardPadding * 1.5)
            .background(
                RoundedRectangle(cornerRadius: GameConstants.cornerRadius * 1.2)
                    .fill(GameConstants.UI.cardMaterial)
                    .shadow(color: GameConstants.cardShadow, radius: 24, x: 0, y: 12)
            )
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                rotation = 0
            }
            
            withAnimation(.easeOut(duration: 0.3)) {
                showConfetti = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                starsScale = 1.0
            }
        }
    }
}

struct LevelFailedOverlay: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var gameManager: GameManager
    @State private var scale = 0.5
    @State private var shake = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .blur(radius: 3)
            
            VStack(spacing: 20) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .rotationEffect(.degrees(Double(shake) * 2))
                
                Text("LEVEL FAILED")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(gameManager.failureMessage)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button(action: {
                        gameManager.retryLevel()
                    }) {
                        Text("Try Again")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 120)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: .blue.opacity(0.5), radius: 10)
                    }
                    
                    Button(action: {
                        gameState.goHome()
                    }) {
                        Text("Home")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 120)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.gray, .gray.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: .gray.opacity(0.5), radius: 10)
                    }
                }
            }
            .padding(GameConstants.cardPadding * 1.5)
            .background(
                RoundedRectangle(cornerRadius: GameConstants.cornerRadius * 1.2)
                    .fill(GameConstants.UI.cardMaterial)
                    .shadow(color: GameConstants.cardShadow, radius: 24, x: 0, y: 12)
            )
            .scaleEffect(scale)
            .offset(x: CGFloat(shake))
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
            }
            
            withAnimation(.default.repeatCount(3, autoreverses: true)) {
                shake = 5
            }
        }
    }
}

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    private func createConfetti() {
        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                position: CGPoint(
                    x: Double.random(in: 0...UIScreen.main.bounds.width),
                    y: -50
                ),
                color: [Color.red, .blue, .green, .yellow, .orange, .pink, .purple].randomElement()!,
                size: Double.random(in: 8...15),
                rotation: Double.random(in: 0...360)
            )
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let size: Double
    let rotation: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var yOffset: Double = 0
    @State private var xOffset: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 0.6)
            .position(piece.position)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                withAnimation(.easeIn(duration: Double.random(in: 2...4))) {
                    yOffset = 900
                    xOffset = Double.random(in: -50...50)
                    rotation = piece.rotation + Double.random(in: 180...720)
                }
            }
    }
}