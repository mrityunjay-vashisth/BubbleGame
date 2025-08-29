// MARK: - HomeScreenView.swift
import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject var gameState: GameState
    @State private var animateGradient = false
    @State private var pulseAnimation = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: GameConstants.levelGridColumns)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated Gradient Background
                FuturisticBackground(animateGradient: $animateGradient)
                
                // Floating Orbs
                FloatingOrbsView(geometry: geometry)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 40) {
                        // Futuristic Header
                        FuturisticHeaderView(
                            completedCount: gameState.completedLevels.count,
                            unlockedCount: gameState.unlockedLevels.count,
                            totalStars: gameState.levelStars.values.reduce(0, +),
                            pulseAnimation: $pulseAnimation
                        )
                        .padding(.top, 40)
                        
                        // Modern Level Grid
                        ModernLevelGrid()
                            .environmentObject(gameState)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation.toggle()
            }
        }
    }
}

// MARK: - Futuristic Background
struct FuturisticBackground: View {
    @Binding var animateGradient: Bool
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.6, blue: 0.4),
                    Color(red: 0.4, green: 0.7, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.8)
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .hueRotation(Angle(degrees: animateGradient ? 30 : 0))
            .opacity(0.15)
            
            // Mesh gradient overlay
            RadialGradient(
                colors: [
                    GameConstants.UI.accent.opacity(0.3),
                    Color.clear,
                    GameConstants.UI.success.opacity(0.2),
                    Color.clear
                ],
                center: animateGradient ? .topLeading : .bottomTrailing,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
            .blendMode(.overlay)
        }
        .background(GameConstants.UI.background)
    }
}

// MARK: - Floating Orbs
struct FloatingOrbsView: View {
    let geometry: GeometryProxy
    @State private var orbPositions: [CGPoint] = []
    
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                GameConstants.balloonColors[index % GameConstants.balloonColors.count].opacity(0.4),
                                GameConstants.balloonColors[index % GameConstants.balloonColors.count].opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 80...150))
                    .blur(radius: 10)
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 15...25))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.5),
                        value: orbPositions
                    )
            }
        }
        .onAppear {
            orbPositions = (0..<8).map { _ in
                CGPoint(
                    x: CGFloat.random(in: 0...geometry.size.width),
                    y: CGFloat.random(in: 0...geometry.size.height)
                )
            }
        }
    }
}

// MARK: - Futuristic Header
struct FuturisticHeaderView: View {
    let completedCount: Int
    let unlockedCount: Int
    let totalStars: Int
    @Binding var pulseAnimation: Bool
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 25) {
            // Logo with Animation
            ZStack {
                // Rotating rings
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [GameConstants.UI.accent, GameConstants.UI.accent.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(rotationAngle))
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [GameConstants.UI.success, GameConstants.UI.success.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 85, height: 85)
                    .rotationEffect(.degrees(-rotationAngle * 1.5))
                
                // Center icon
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 35, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [GameConstants.UI.accent, GameConstants.UI.warning],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
            }
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }
            
            // Title
            VStack(spacing: 4) {
                Text("BUBBLE")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [GameConstants.UI.accent, GameConstants.UI.warning],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("POP")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [GameConstants.UI.success, GameConstants.UI.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .shadow(color: GameConstants.UI.accent.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Futuristic Stats Display
            VStack(spacing: 15) {
                HStack(spacing: 30) {
                    StatsCapsule(
                        value: completedCount,
                        label: "MASTERED",
                        color: GameConstants.UI.success,
                        icon: "checkmark.circle.fill"
                    )
                    
                    StatsCapsule(
                        value: unlockedCount,
                        label: "UNLOCKED",
                        color: GameConstants.UI.accent,
                        icon: "lock.open.fill"
                    )
                }
                
                // Total Stars Display
                if totalStars > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                        Text("\(totalStars) / \(completedCount * 3)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(GameConstants.UI.secondaryText)
                        Text("STARS EARNED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(GameConstants.UI.tertiaryText)
                            .tracking(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
}

// MARK: - Stats Capsule
struct StatsCapsule: View {
    let value: Int
    let label: String
    let color: Color
    let icon: String
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .blur(radius: isAnimating ? 8 : 4)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(GameConstants.UI.primaryText)
                
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(GameConstants.UI.secondaryText)
                    .tracking(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Modern Level Grid
struct ModernLevelGrid: View {
    @EnvironmentObject var gameState: GameState
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: GameConstants.levelGridColumns)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("CHOOSE YOUR CHALLENGE")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(GameConstants.UI.secondaryText)
                .tracking(1.5)
                .padding(.horizontal, 25)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(1...GameConstants.maxLevels, id: \.self) { level in
                    FuturisticLevelCard(level: level)
                        .environmentObject(gameState)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Futuristic Level Card
struct FuturisticLevelCard: View {
    let level: Int
    @EnvironmentObject var gameState: GameState
    @State private var isPressed = false
    @State private var glowAnimation = false
    
    private var isUnlocked: Bool { gameState.unlockedLevels.contains(level) }
    private var isCompleted: Bool { gameState.completedLevels.contains(level) }
    private var starCount: Int { gameState.getStarsForLevel(level) }
    
    var body: some View {
        Button(action: { 
            if isUnlocked {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    gameState.selectLevel(level)
                }
            }
        }) {
            ZStack {
                // Background with gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: cardGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: borderColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isCompleted ? 2 : 1
                            )
                    )
                
                // Glow effect for 3-star levels
                if starCount == 3 {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.yellow, lineWidth: 2)
                        .blur(radius: glowAnimation ? 8 : 4)
                        .opacity(glowAnimation ? 0.6 : 0.3)
                }
                
                // Content
                VStack(spacing: 6) {
                    if isUnlocked {
                        // Level number
                        Text("\(level)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: textGradientColors,
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Star Rating Display
                        if isCompleted {
                            HStack(spacing: 2) {
                                ForEach(1...3, id: \.self) { star in
                                    Image(systemName: star <= starCount ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundColor(
                                            star <= starCount ? starColor : Color.gray.opacity(0.3)
                                        )
                                }
                            }
                        } else {
                            // Empty stars for unlocked but not played
                            HStack(spacing: 2) {
                                ForEach(1...3, id: \.self) { _ in
                                    Image(systemName: "star")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.gray.opacity(0.3))
                                }
                            }
                        }
                    } else {
                        // Locked state
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(GameConstants.UI.tertiaryText.opacity(0.5))
                    }
                }
            }
        }
        .frame(width: GameConstants.levelBoxSize, height: GameConstants.levelBoxSize)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .shadow(color: shadowColor, radius: isUnlocked ? 8 : 2, x: 0, y: 4)
        .disabled(!isUnlocked)
        .onAppear {
            if isCompleted {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowAnimation = true
                }
            }
        }
    }
    
    private var cardGradientColors: [Color] {
        if isCompleted {
            return [
                GameConstants.UI.warning.opacity(0.15),
                GameConstants.UI.warning.opacity(0.08)
            ]
        } else if isUnlocked {
            return [
                GameConstants.UI.surface,
                GameConstants.UI.surface.opacity(0.95)
            ]
        } else {
            return [
                GameConstants.UI.surface.opacity(0.5),
                GameConstants.UI.surface.opacity(0.3)
            ]
        }
    }
    
    private var borderColors: [Color] {
        if isCompleted {
            return [GameConstants.UI.warning, GameConstants.UI.warning.opacity(0.5)]
        } else if isUnlocked {
            return [GameConstants.UI.accent.opacity(0.3), GameConstants.UI.accent.opacity(0.1)]
        } else {
            return [GameConstants.UI.divider, GameConstants.UI.divider.opacity(0.5)]
        }
    }
    
    private var textGradientColors: [Color] {
        if isCompleted {
            return [GameConstants.UI.warning, GameConstants.UI.accent]
        } else {
            return [GameConstants.UI.primaryText, GameConstants.UI.secondaryText]
        }
    }
    
    private var shadowColor: Color {
        if isCompleted {
            return GameConstants.UI.warning.opacity(0.3)
        } else if isUnlocked {
            return GameConstants.cardShadow
        } else {
            return Color.clear
        }
    }
    
    private var starColor: Color {
        switch starCount {
        case 3: return Color.yellow
        case 2: return Color.gray
        case 1: return Color.brown.opacity(0.8)
        default: return Color.gray.opacity(0.3)
        }
    }
}