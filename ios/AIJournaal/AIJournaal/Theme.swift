import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

enum Theme {
    /// Bijna-zwart aubergine: de ondergrond.
    static let ink = Color(hex: 0x120722)
    static let plum = Color(hex: 0x2A0F4A)
    static let violet = Color(hex: 0x8B4DFF)
    static let orchid = Color(hex: 0xB98CFF)
    static let amber = Color(hex: 0xFF8A1F)
    static let apricot = Color(hex: 0xFFB96B)
    /// Warm wit voor tekst.
    static let cream = Color(hex: 0xFBF3EA)

    static let warm = LinearGradient(
        colors: [apricot, amber],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let duotone = LinearGradient(
        colors: [violet, Color(hex: 0xD86A9A), amber],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Vloeiende overgang van paars (0) naar oranje (1).
    static func blend(_ fraction: Double) -> Color {
        let f = min(1, max(0, fraction))
        return Color(
            .sRGB,
            red: (139 + (255 - 139) * f) / 255,
            green: (77 + (138 - 77) * f) / 255,
            blue: (255 + (31 - 255) * f) / 255,
            opacity: 1
        )
    }

    static func serif(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

/// Kleine kapitalen met ruime spatiëring, voor rubriekkoppen.
struct Eyebrow: View {
    let text: String
    var color: Color = Theme.apricot

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.8)
            .foregroundStyle(color)
    }
}

/// Matglazen kaart met een zweem paars en oranje.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 28

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay {
                        shape.fill(
                            LinearGradient(
                                colors: [Theme.violet.opacity(0.22), Theme.amber.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    .overlay {
                        shape.strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.22), Color.white.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                    }
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 28) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}
