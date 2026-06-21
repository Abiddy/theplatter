import SwiftUI

struct CombosView: View {
    @Environment(ScanSessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    let onTweakPreferences: () -> Void
    let onRegenerate: () -> Void

    @State private var showOrderSheet = false
    @State private var selectedCombo: Combo?
    @State private var showShareSheet = false
    @State private var shareText = ""

    private var subtitle: String {
        let name = session.menu?.restaurantName ?? session.restaurantName ?? "Your Restaurant"
        return "\(name) · Party of \(session.constraints.partySize) · \(session.constraints.budgetFormatted) budget"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                FlowStepperView(currentStep: .results)

                if !session.aiSummary.isEmpty {
                    AISummaryBanner(summary: session.aiSummary)
                }

                ConstraintTagRow(tags: session.constraintTags)

                ForEach(session.combos) { combo in
                    ComboCard(
                        combo: combo,
                        onOrder: {
                            selectedCombo = combo
                            showOrderSheet = true
                        },
                        onShare: {
                            shareText = formatShareText(combo)
                            showShareSheet = true
                        }
                    )
                }

                HStack(spacing: 12) {
                    PlatterSecondaryButton(title: "Tweak", icon: "pencil") {
                        onTweakPreferences()
                    }
                    PlatterSecondaryButton(title: "Regenerate", icon: "arrow.clockwise", style: .regenerate) {
                        onRegenerate()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(PlatterColors.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showOrderSheet) {
            if let combo = selectedCombo {
                OrderSummarySheet(combo: combo, restaurantName: session.menu?.restaurantName)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: shareText)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            FlowBackButton {
                dismiss()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Your Combos")
                    .font(PlatterFont.title(28))
                    .foregroundStyle(PlatterColors.textPrimary)
                Text(subtitle)
                    .font(PlatterFont.body(14))
                    .foregroundStyle(PlatterColors.textSecondary)
            }

            Spacer(minLength: 0)

            Button {} label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16))
                    .foregroundStyle(PlatterColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(PlatterColors.neutralGray)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 4)
    }

    private func formatShareText(_ combo: Combo) -> String {
        var lines = ["\(combo.title) — \(session.menu?.restaurantName ?? "Platter")", ""]
        for item in combo.lineItems {
            lines.append("\(item.quantity)x \(item.name) — \(item.lineTotalFormatted)")
        }
        lines.append("")
        lines.append("Total: \(combo.totalFormatted)")
        lines.append("Saved with Platter AI ✨")
        return lines.joined(separator: "\n")
    }
}

struct OrderSummarySheet: View {
    let combo: Combo
    let restaurantName: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Show this to your server")
                    .font(PlatterFont.headline(18))
                    .foregroundStyle(PlatterColors.textPrimary)

                if let restaurantName {
                    Text(restaurantName)
                        .font(PlatterFont.body(14))
                        .foregroundStyle(PlatterColors.textSecondary)
                }

                VStack(spacing: 10) {
                    ForEach(combo.lineItems) { item in
                        HStack {
                            Text("\(item.quantity)x \(item.name)")
                            Spacer()
                            Text(item.lineTotalFormatted)
                        }
                        .font(PlatterFont.body(15))
                    }
                }
                .padding()
                .background(PlatterColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Text("Total")
                        .font(PlatterFont.headline(17))
                    Spacer()
                    Text(combo.totalFormatted)
                        .font(.system(size: 22, weight: .bold, design: .default))
                }

                Text("Tips & tax not included")
                    .font(PlatterFont.caption(12))
                    .foregroundStyle(PlatterColors.textSecondary)

                Spacer()

                PlatterPrimaryButton(title: "Done") {
                    dismiss()
                }
            }
            .padding(20)
            .navigationTitle(combo.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        CombosView(onTweakPreferences: {}, onRegenerate: {})
    }
    .environment(CombosView.previewSession)
}

private extension CombosView {
    static var previewSession: ScanSessionStore {
        let session = ScanSessionStore()
        session.menu = MockDataService.osteriaBellaMenu()
        session.constraints.partySize = 6
        session.constraints.budgetCents = 10_000
        session.constraints.dietaryRules = [.vegetarian, .noFish]
        session.constraints.vegetarianCount = 2
        let result = ComboOptimizer.generate(menu: session.menu!, constraints: session.constraints)
        session.combos = result.combos
        session.aiSummary = result.aiSummary
        session.constraintTags = result.constraintTags
        return session
    }
}
