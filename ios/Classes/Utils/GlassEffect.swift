import SwiftUI

/// A polyfill for the hypothetical Glass API to enable Liquid Glass effects
/// on standard iOS devices (iOS 15+).
@available(iOS 15.0, *)
public struct Glass {
    var material: Material
    var tintColor: Color?
    var isInteractive: Bool = false
    
    public static let regular = Glass(material: .regularMaterial)
    public static let thick = Glass(material: .thickMaterial)
    public static let thin = Glass(material: .thinMaterial)
    public static let ultraThin = Glass(material: .ultraThinMaterial)
    
    public func tint(_ color: Color) -> Glass {
        var copy = self
        copy.tintColor = color
        return copy
    }
    
    public func interactive() -> Glass {
        var copy = self
        copy.isInteractive = true
        return copy
    }
}

@available(iOS 15.0, *)
public extension View {
    func glassEffect(_ glass: Glass, in shape: some Shape) -> some View {
        self.background(
            ZStack {
                // Base Material
                shape.fill(glass.material)
                
                // Tint Overlay
                if let color = glass.tintColor {
                    shape.fill(color.opacity(0.15))
                }
                
                // Interactive Effect (Highlight/Shadow hint)
                if glass.isInteractive {
                    shape.stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .blendMode(.overlay)
                }
            }
        )
        // Ensure the content itself is clipped to the shape if needed,
        // though usually background is enough.
        .clipShape(shape)
        // Add a subtle shadow for depth
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
