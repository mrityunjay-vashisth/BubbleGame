import SwiftUI

struct BalloonPool {
    private let maxPoolSize = 20
    private var availableViews: Set<Int> = []
    private var activeViews: [Int: GameBalloon] = [:]
    private var nextId = 0
    
    init() {
        for i in 0..<maxPoolSize {
            availableViews.insert(i)
        }
    }
    
    mutating func getBalloon(x: CGFloat, y: CGFloat, isPositive: Bool, points: Int, colorIndex: Int) -> GameBalloon? {
        guard let viewId = availableViews.first else {
            return nil
        }
        
        availableViews.remove(viewId)
        
        let balloon = GameBalloon(
            x: x,
            y: y,
            isPositive: isPositive,
            points: points,
            colorIndex: colorIndex
        )
        
        activeViews[balloon.id] = balloon
        return balloon
    }
    
    mutating func returnBalloon(_ balloon: GameBalloon) {
        activeViews.removeValue(forKey: balloon.id)
        availableViews.insert(balloon.id)
    }
    
    mutating func reset() {
        availableViews = Set(0..<maxPoolSize)
        activeViews.removeAll()
    }
}

struct RecycledBalloonView: View {
    let balloon: GameBalloon
    let onTap: () -> Void
    @State private var isVisible = false
    @State private var scale: Double = 0.1
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    
    private var balloonSize: CGSize {
        let multiplier = max(0.4, 0.3 + (Double(balloon.points) * 0.2))
        return CGSize(
            width: GameConstants.balloonSize.width * multiplier,
            height: GameConstants.balloonSize.height * multiplier
        )
    }
    
    var body: some View {
        if isVisible {
            BalloonView(balloon: balloon, onTap: onTap)
                .transition(.scale.combined(with: .opacity))
        }
    }
    
    func show() {
        withAnimation(.linear(duration: 0.15)) {
            isVisible = true
            scale = 1.0
        }
    }
    
    func hide(completion: @escaping () -> Void) {
        withAnimation(.linear(duration: 0.1)) {
            isVisible = false
            scale = 0.1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion()
        }
    }
    
    func reset() {
        isVisible = false
        scale = 0.1
        offset = .zero
        rotation = 0
    }
}

class BalloonPoolManager: ObservableObject {
    @Published var visibleBalloons: [GameBalloon] = []
    private var pool = BalloonPool()
    private var removalTimers: [Int: Timer] = [:]
    
    @MainActor
    func addBalloon(x: CGFloat, y: CGFloat, isPositive: Bool, points: Int, colorIndex: Int, lifetime: TimeInterval) -> GameBalloon? {
        guard let balloon = pool.getBalloon(
            x: x,
            y: y,
            isPositive: isPositive,
            points: points,
            colorIndex: colorIndex
        ) else {
            return nil
        }
        
        visibleBalloons.append(balloon)
        
        let timer = Timer.scheduledTimer(withTimeInterval: lifetime, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.removeBalloon(balloon)
            }
        }
        removalTimers[balloon.id] = timer
        
        return balloon
    }
    
    @MainActor
    func removeBalloon(_ balloon: GameBalloon) {
        removalTimers[balloon.id]?.invalidate()
        removalTimers.removeValue(forKey: balloon.id)
        
        if let index = visibleBalloons.firstIndex(where: { $0.id == balloon.id }) {
            visibleBalloons.remove(at: index)
            pool.returnBalloon(balloon)
        }
    }
    
    @MainActor
    func popBalloon(_ balloon: GameBalloon) {
        removeBalloon(balloon)
    }
    
    @MainActor
    func reset() {
        for timer in removalTimers.values {
            timer.invalidate()
        }
        removalTimers.removeAll()
        visibleBalloons.removeAll()
        pool.reset()
    }
}