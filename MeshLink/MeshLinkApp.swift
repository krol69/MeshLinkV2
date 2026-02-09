import SwiftUI

@main
struct MeshLinkApp: App {
    @StateObject private var vm = MeshViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if vm.isSetup {
                    MainView()
                        .environmentObject(vm)
                } else {
                    SetupView()
                        .environmentObject(vm)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Theme
struct Theme {
    static let bg0 = Color(hex: "080C12")
    static let bg1 = Color(hex: "0D1117")
    static let bg2 = Color(hex: "141B24")
    static let surface = Color.white.opacity(0.03)
    static let border = Color.white.opacity(0.06)
    static let borderAccent = Color(hex: "34D399").opacity(0.2)
    static let accent = Color(hex: "34D399")
    static let accentBlue = Color(hex: "06B6D4")
    static let danger = Color(hex: "F87171")
    static let warning = Color(hex: "FBBF24")
    static let text1 = Color(hex: "E2E8F0")
    static let text2 = Color.white.opacity(0.5)
    static let textMuted = Color.white.opacity(0.25)
    static let purple = Color(hex: "818CF8")
    
    static let gradient = LinearGradient(
        colors: [accent, accentBlue],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradientFull = LinearGradient(
        colors: [accent, accentBlue, purple],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: UInt64
        switch h.count {
        case 6: (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }
}

extension String {
    var meshColor: Color {
        var hash: Int = 0
        for char in self.unicodeScalars { hash = Int(char.value) &+ ((hash << 5) &- hash) }
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.65, brightness: 0.65)
    }
}
