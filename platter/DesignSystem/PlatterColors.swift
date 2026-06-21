import SwiftUI

enum PlatterColors {
    // Primary brand — vibrant orange-red from designs (#FF4522)
    static let brandOrange = Color(red: 1.0, green: 0.271, blue: 0.133)
    static let brandOrangeLight = Color(red: 1.0, green: 0.945, blue: 0.937)

    // Surfaces
    static let background = Color(red: 0.973, green: 0.973, blue: 0.973)
    static let cardWhite = Color.white
    static let neutralGray = Color(red: 0.933, green: 0.933, blue: 0.933)
    static let inactiveFill = Color(red: 0.922, green: 0.922, blue: 0.922)

    // Text
    static let textPrimary = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let textSecondary = Color(red: 0.557, green: 0.557, blue: 0.576)
    static let textTertiary = Color(red: 0.682, green: 0.682, blue: 0.698)

    // Semantic
    static let stepComplete = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let savingsGreenBg = Color(red: 0.878, green: 0.949, blue: 0.894)
    static let savingsGreenText = Color(red: 0.133, green: 0.545, blue: 0.298)
    static let regenerateBg = Color(red: 1.0, green: 0.941, blue: 0.941)
    static let regenerateText = Color(red: 0.878, green: 0.224, blue: 0.224)
    static let aiBannerDark = Color(red: 0.071, green: 0.071, blue: 0.071)

    // Borders & misc
    static let chipBorder = Color(red: 0.898, green: 0.898, blue: 0.918)
    static let tagBackground = Color(red: 0.945, green: 0.945, blue: 0.945)
    static let verifiedBadge = brandOrange
    static let divider = Color(red: 0.898, green: 0.898, blue: 0.918)
    static let shadow = Color.black.opacity(0.06)

    // Legacy aliases — keep call sites working during migration
    static let backgroundCream = background
    static let successGreen = savingsGreenText
    static let savingsYellow = savingsGreenBg
    static let savingsYellowText = savingsGreenText
    static let tagYellow = tagBackground
}
