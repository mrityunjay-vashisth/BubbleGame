import SwiftUI

struct SpawnAreaDebugView: View {
    let screenSize: CGSize
    let showBounds: Bool
    
    var body: some View {
        if showBounds {
            let spawnArea = GameConstants.getSpawnArea(screenWidth: screenSize.width, screenHeight: screenSize.height)
            
            Rectangle()
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
                .frame(
                    width: CGFloat(spawnArea.x.upperBound - spawnArea.x.lowerBound),
                    height: CGFloat(spawnArea.y.upperBound - spawnArea.y.lowerBound)
                )
                .position(
                    x: CGFloat((spawnArea.x.lowerBound + spawnArea.x.upperBound) / 2),
                    y: CGFloat((spawnArea.y.lowerBound + spawnArea.y.upperBound) / 2)
                )
                .allowsHitTesting(false)
        }
    }
}

// Add this to GameConstants for easy toggling during development
extension GameConstants {
    static let showSpawnAreaBounds: Bool = false // Set to true to see spawn bounds
}