import SwiftUI

struct ForgeTheme {
    // Generated colors from YAML
    static let surface = Color(hex: "0f1417")
    static let surfaceDim = Color(hex: "0f1417")
    static let surfaceBright = Color(hex: "353a3d")
    static let surfaceContainerLowest = Color(hex: "0a0f12")
    static let surfaceContainerLow = Color(hex: "181c1f")
    static let surfaceContainer = Color(hex: "1c2023")
    static let surfaceContainerHigh = Color(hex: "262b2e")
    static let surfaceContainerHighest = Color(hex: "313539")
    static let onSurface = Color(hex: "dfe3e7")
    static let onSurfaceVariant = Color(hex: "bec8d0")
    static let inverseSurface = Color(hex: "dfe3e7")
    static let inverseOnSurface = Color(hex: "2c3134")
    static let outline = Color(hex: "889299")
    static let outlineVariant = Color(hex: "3e484e")
    
    static let surfaceTint = Color(hex: "79d1ff")
    static let primary = Color(hex: "b6e3ff")
    static let onPrimary = Color(hex: "003549")
    static let primaryContainer = Color(hex: "66ccff")
    static let onPrimaryContainer = Color(hex: "005573")
    static let inversePrimary = Color(hex: "006689")
    
    static let secondary = Color(hex: "ffb3ad")
    static let onSecondary = Color(hex: "68000a")
    static let secondaryContainer = Color(hex: "b6021a")
    static let onSecondaryContainer = Color(hex: "ffc2bd")
    
    static let tertiary = Color(hex: "ffd6a5")
    static let onTertiary = Color(hex: "462a00")
    static let tertiaryContainer = Color(hex: "fcb24a")
    static let onTertiaryContainer = Color(hex: "6f4600")
    
    static let error = Color(hex: "ffb4ab")
    static let onError = Color(hex: "690005")
    static let errorContainer = Color(hex: "93000a")
    static let onErrorContainer = Color(hex: "ffdad6")
    
    static let background = Color(hex: "0f1417")
    static let onBackground = Color(hex: "dfe3e7")
    static let surfaceVariant = Color(hex: "313539")
    
    // Core Brand Specs
    static let pureBlack = Color(hex: "000000") // pure black foundation
    static let containerBg = Color(hex: "080808") // primary containers
    static let activeHover = Color(hex: "111111")
    static let border = Color(hex: "222222")
    static let borderMuted = Color(hex: "444444")
    
    // Brand Accent & Priorities
    static let aiAccent = Color(hex: "22D3EE") // Cyan
    static let highPriority = Color(hex: "EF4444") // Red
    static let mediumPriority = Color(hex: "F97316") // Orange
    static let lowPriority = Color(hex: "3B82F6") // Blue
    static let success = Color(hex: "22C55E") // Green
}

extension Font {
    static var forgeH1: Font { .system(size: 24, weight: .bold, design: .default) }
    static var forgeH2: Font { .system(size: 18, weight: .semibold, design: .default) }
    static var forgeBodyMono: Font { .system(size: 14, weight: .regular, design: .monospaced) }
    static var forgeCodeSm: Font { .system(size: 12, weight: .medium, design: .monospaced) }
    static var forgeLabelCaps: Font { .system(size: 10, weight: .bold, design: .monospaced) }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
