import SwiftUI

struct PlatterPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(PlatterFont.headline(17))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(PlatterColors.brandOrange)
            .clipShape(Capsule())
        }
        .disabled(isLoading)
    }
}

struct PlatterSecondaryButton: View {
    enum Style {
        case neutral
        case regenerate
    }

    let title: String
    var icon: String? = nil
    var outlined: Bool = false
    var style: Style = .neutral
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(PlatterFont.headline(15))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .overlay {
                Capsule()
                    .stroke(borderColor, lineWidth: showBorder ? 1.5 : 1)
            }
            .clipShape(Capsule())
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .neutral:
            outlined ? PlatterColors.brandOrange : PlatterColors.textPrimary
        case .regenerate:
            PlatterColors.regenerateText
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .neutral:
            outlined ? PlatterColors.cardWhite : PlatterColors.cardWhite
        case .regenerate:
            PlatterColors.regenerateBg
        }
    }

    private var borderColor: Color {
        switch style {
        case .neutral:
            outlined ? PlatterColors.brandOrange : PlatterColors.chipBorder
        case .regenerate:
            PlatterColors.regenerateText.opacity(0.35)
        }
    }

    private var showBorder: Bool {
        outlined || style == .regenerate
    }
}
