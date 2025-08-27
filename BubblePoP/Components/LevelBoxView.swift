// MARK: - LevelBoxView.swift
import SwiftUI

struct LevelBoxView: View {
    let level: Int
    @EnvironmentObject var gameState: GameState
    
    private var isUnlocked: Bool { gameState.unlockedLevels.contains(level) }
    private var isCompleted: Bool { gameState.completedLevels.contains(level) }
    private var pointsNeeded: Int { LevelConfiguration.pointsNeeded(for: level) }
    private var timeAllowed: Int { LevelConfiguration.timeAllowed(for: level) }
    
    var body: some View {
        Button(action: { gameState.selectLevel(level) }) {
            ZStack {
                // Background with state-based styling
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundGradient)
                    .overlay(borderOverlay)
                    .shadow(
                        color: shadowColor,
                        radius: isUnlocked ? 8 : 0
                    )
                
                // Content
                VStack(spacing: 6) {
                    if isUnlocked {
                        UnlockedLevelContent(
                            level: level,
                            isCompleted: isCompleted,
                            pointsNeeded: pointsNeeded,
                            timeAllowed: timeAllowed
                        )
                    } else {
                        LockedLevelContent(level: level)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: GameConstants.levelBoxSize, height: GameConstants.levelBoxSize)
        .scaleEffect(levelScale)
        .animation(.spring(duration: 0.3), value: isCompleted)
        .animation(.spring(duration: 0.3), value: isUnlocked)
        .disabled(!isUnlocked)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundGradient: LinearGradient {
        if isCompleted {
            return LinearGradient(
                colors: [Color.yellow.opacity(0.4), Color.orange.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isUnlocked {
            return LinearGradient(
                colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(borderColor, lineWidth: 2)
    }
    
    private var borderColor: Color {
        isCompleted ? Color.yellow.opacity(0.8) :
        isUnlocked ? Color.cyan.opacity(0.5) : Color.gray.opacity(0.3)
    }
    
    private var shadowColor: Color {
        isCompleted ? .yellow.opacity(0.4) :
        isUnlocked ? .cyan.opacity(0.3) : .clear
    }
    
    private var levelScale: Double {
        isCompleted ? 1.05 : isUnlocked ? 1.0 : 0.9
    }
}

struct UnlockedLevelContent: View {
    let level: Int
    let isCompleted: Bool
    let pointsNeeded: Int
    let timeAllowed: Int
    
    var body: some View {
        VStack(spacing: 6) {
            // Level number with completion indicator
            HStack(spacing: 4) {
                if isCompleted {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                
                Text("\(level)")
                    .font(.system(size: isCompleted ? 20 : 22, weight: .black, design: .rounded))
                    .foregroundStyle(levelNumberGradient)
            }
            
            // Level requirements
            VStack(spacing: 2) {
                Text("\(pointsNeeded)pts")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(timeAllowed)s")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(timeColor)
            }
        }
    }
    
    private var levelNumberGradient: LinearGradient {
        LinearGradient(
            colors: isCompleted ? [.yellow, .orange] : [.white, .cyan],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var timeColor: Color {
        isCompleted ? .orange.opacity(0.8) : .cyan.opacity(0.8)
    }
}

struct LockedLevelContent: View {
    let level: Int
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundColor(.gray.opacity(0.6))
            
            Text("\(level)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.gray.opacity(0.6))
        }
    }
}
