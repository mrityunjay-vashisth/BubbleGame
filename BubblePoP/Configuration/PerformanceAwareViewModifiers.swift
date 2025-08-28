import SwiftUI

// MARK: - Performance-Aware View Modifiers
extension View {
    /// Applies blur only if Metal effects are supported, otherwise applies no effect
    @ViewBuilder
    func performanceAwareBlur(radius: CGFloat) -> some View {
        if PerformanceDetector.shared.enableBlurEffects {
            self.blur(radius: radius)
        } else {
            self
        }
    }
    
    /// Applies shadow only if Metal effects are supported, otherwise applies no effect  
    @ViewBuilder
    func performanceAwareShadow(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        if PerformanceDetector.shared.enableShadowEffects {
            self.shadow(color: color, radius: radius, x: x, y: y)
        } else {
            self
        }
    }
    
    /// Uses advanced materials if supported, otherwise falls back to solid colors
    @ViewBuilder
    func performanceAwareBackground(_ material: Material, fallback: Color = Color.black.opacity(0.1)) -> some View {
        if PerformanceDetector.shared.enableAdvancedMaterials {
            self.background(material)
        } else {
            self.background(fallback)
        }
    }
    
    /// Conditional ultra thin material with fallback
    @ViewBuilder
    func performanceAwareUltraThinMaterial(fallback: Color = Color.white.opacity(0.1)) -> some View {
        if PerformanceDetector.shared.enableAdvancedMaterials {
            self.background(.ultraThinMaterial)
        } else {
            self.background(fallback)
        }
    }
    
    /// Conditional thin material with fallback
    @ViewBuilder
    func performanceAwareThinMaterial(fallback: Color = Color.white.opacity(0.2)) -> some View {
        if PerformanceDetector.shared.enableAdvancedMaterials {
            self.background(.thinMaterial)
        } else {
            self.background(fallback)
        }
    }
}

// MARK: - Performance-Aware Color Extensions
extension Color {
    /// Returns a performance-appropriate shadow color
    static func performanceAwareShadow(_ baseColor: Color, opacity: Double = 0.3) -> Color {
        if PerformanceDetector.shared.enableShadowEffects {
            return baseColor.opacity(opacity)
        } else {
            return Color.clear
        }
    }
}