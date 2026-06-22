import SwiftUI

struct PreferencesView: View {
    @Environment(ScanSessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    let onContinue: () -> Void

    @State private var showError = false
    @State private var showAllDietary = false

    var body: some View {
        @Bindable var session = session

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                FlowStepperView(currentStep: .preferences)
                    .padding(.top, 4)

                PlatterSectionCard(title: "Party Size") {
                    PartySizeStepper(partySize: $session.constraints.partySize, range: 1...20)
                }

                PlatterSectionCard(title: "Total Budget") {
                    BudgetSlider(
                        budgetCents: $session.constraints.budgetCents,
                        range: 2_000...30_000,
                        step: 500,
                        partySize: session.constraints.partySize
                    )
                }

                PlatterSectionCard(title: "Dietary Restrictions") {
                    dietaryContent(session: session)
                }

                PlatterSectionCard(title: "Optimize For") {
                    optimizeContent(session: session)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(PlatterColors.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            stickyFooter(session: session)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: session.constraints.dietaryRules) { _, rules in
            if rules.contains(.vegetarian), session.constraints.vegetarianCount == 0 {
                session.constraints.vegetarianCount = 1
            }
        }
        .alert("Couldn't get recommendations", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(session.errorMessage ?? "Unknown error")
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            FlowBackButton {
                dismiss()
            }

            Text("Preferences")
                .font(PlatterFont.sectionLabel(12))
                .foregroundStyle(PlatterColors.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    private func stickyFooter(session: ScanSessionStore) -> some View {
        VStack(spacing: 10) {
            if let message = session.errorMessage {
                Text(message)
                    .font(PlatterFont.body(13))
                    .foregroundStyle(.red)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            PlatterPrimaryButton(
                title: "Get Recommendations",
                icon: "sparkles",
                isLoading: session.isLoading
            ) {
                Task {
                    await session.generateCombos()
                    if !session.combos.isEmpty {
                        onContinue()
                    } else if session.errorMessage != nil {
                        showError = true
                    } else {
                        session.errorMessage = "Couldn't reach the server. Check your connection and try again."
                        showError = true
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background {
            PlatterColors.background
                .shadow(color: .black.opacity(0.06), radius: 8, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func dietaryContent(session: ScanSessionStore) -> some View {
        @Bindable var session = session

        return VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(visibleDietaryRules(selected: session.constraints.dietaryRules)) { rule in
                    DietaryChip(
                        rule: rule,
                        isSelected: session.constraints.dietaryRules.contains(rule)
                    ) {
                        toggleDietary(rule, session: session)
                    }
                }
            }

            Button {
                withAnimation(.snappy) {
                    showAllDietary.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(showAllDietary ? "See less" : "See more")
                        .font(PlatterFont.caption(13))
                    Image(systemName: showAllDietary ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(PlatterColors.brandOrange)
            }
            .buttonStyle(.plain)

            if session.constraints.dietaryRules.contains(.vegetarian) {
                HStack {
                    Text("How many vegetarians?")
                        .font(PlatterFont.body(14))
                        .foregroundStyle(PlatterColors.textSecondary)
                    Spacer()
                    Stepper(
                        "\(session.constraints.vegetarianCount)",
                        value: $session.constraints.vegetarianCount,
                        in: 1...session.constraints.partySize
                    )
                    .font(PlatterFont.headline(15))
                }
            }
        }
    }

    private func optimizeContent(session: ScanSessionStore) -> some View {
        VStack(spacing: 10) {
            ForEach(OptimizeGoal.allCases) { goal in
                OptimizeOptionCard(
                    goal: goal,
                    isSelected: session.constraints.optimizeGoals.contains(goal)
                ) {
                    toggleGoal(goal, session: session)
                }
            }
        }
    }

    private func visibleDietaryRules(selected: Set<DietaryRule>) -> [DietaryRule] {
        if showAllDietary {
            return DietaryRule.primary + DietaryRule.extended
        }
        return DietaryRule.primary + DietaryRule.extended.filter { selected.contains($0) }
    }

    private func toggleGoal(_ goal: OptimizeGoal, session: ScanSessionStore) {
        if session.constraints.optimizeGoals.contains(goal) {
            if session.constraints.optimizeGoals.count > 1 {
                session.constraints.optimizeGoals.remove(goal)
            }
        } else {
            session.constraints.optimizeGoals.insert(goal)
        }
    }

    private func toggleDietary(_ rule: DietaryRule, session: ScanSessionStore) {
        if session.constraints.dietaryRules.contains(rule) {
            session.constraints.dietaryRules.remove(rule)
            if rule == .vegetarian {
                session.constraints.vegetarianCount = 0
            }
        } else {
            session.constraints.dietaryRules.insert(rule)
            if rule == .vegetarian, session.constraints.vegetarianCount == 0 {
                session.constraints.vegetarianCount = 1
            }
        }
    }
}

#Preview {
    NavigationStack {
        PreferencesView(onContinue: {})
    }
    .environment(ScanSessionStore())
}
