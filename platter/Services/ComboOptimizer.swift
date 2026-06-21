import Foundation

/// Deterministic combo optimizer — the LLM never does math.
enum ComboOptimizer {
    private struct Candidate {
        var lineItems: [ComboLineItem]
        var totalCents: Int
        var itemCount: Int
        var uniqueDishes: Int
        var vegItemCount: Int
        var servingScore: Double
        var mainServings: Double
        var appetizerServings: Double
        var dessertServings: Double
        var drinkCount: Int
        var duplicatePenalty: Double
        var score: Double
    }

    static func generate(menu: Menu, constraints: Constraints) -> ComboGenerationResult {
        let eligible = filterItems(menu.allItems, constraints: constraints)
        let referenceSpend = referenceSpendCents(partySize: constraints.partySize, items: eligible)
        let candidates = buildCandidates(from: eligible, constraints: constraints)

        let sorted = candidates
            .sorted { $0.score > $1.score }
            .filter { isDiverse($0, against: []) }

        var selected: [Candidate] = []
        for candidate in sorted {
            if selected.count >= 3 { break }
            if selected.allSatisfy({ !isTooSimilar($0, to: candidate) }) {
                selected.append(candidate)
            }
        }

        if selected.isEmpty, let fallback = candidates.max(by: { $0.score < $1.score }) {
            selected = [fallback]
        }

        let combos = selected.enumerated().map { index, candidate in
            let meta = comboMetadata(
                rank: index + 1,
                candidate: candidate,
                constraints: constraints,
                referenceSpend: referenceSpend
            )
            return Combo(
                id: UUID(),
                rank: index + 1,
                isTopPick: index == 0,
                title: meta.title,
                subtitle: meta.subtitle,
                lineItems: candidate.lineItems,
                totalCents: candidate.totalCents,
                savingsCents: max(0, min(constraints.budgetCents, referenceSpend) - candidate.totalCents)
            )
        }

        return ComboGenerationResult(
            combos: combos,
            aiSummary: buildSummary(combos: combos, constraints: constraints),
            constraintTags: buildConstraintTags(constraints: constraints)
        )
    }

    private static func filterItems(_ items: [MenuItem], constraints: Constraints) -> [MenuItem] {
        items.filter { item in
            if constraints.dietaryRules.contains(.vegan), !item.isVegan { return false }
            if constraints.dietaryRules.contains(.vegetarian), !item.isVegetarian, !item.isVegan { return false }
            if constraints.dietaryRules.contains(.noFish), item.containsFish { return false }
            if constraints.dietaryRules.contains(.noShellfish), item.containsFish { return false }
            if constraints.dietaryRules.contains(.noNuts), item.containsNuts { return false }
            if constraints.dietaryRules.contains(.noPork), item.containsPork { return false }
            if constraints.dietaryRules.contains(.glutenFree), !item.isGlutenFree { return false }
            if constraints.dietaryRules.contains(.halal), item.containsPork { return false }
            if constraints.dietaryRules.contains(.kosher), item.containsPork { return false }
            // Extended rules (dairy-free, keto, etc.) need richer item tags from the
            // vision parse — they pass through here and are enforced server-side.
            return true
        }
    }

    private static func buildCandidates(from items: [MenuItem], constraints: Constraints) -> [Candidate] {
        guard !items.isEmpty else { return [] }

        var candidates: [Candidate] = []
        let itemLookup = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        let hardCap = Int(Double(constraints.budgetCents) * 1.12)
        let maxPartialStates = 3_000
        var beam: [([ComboLineItem], Int, Int)] = [([], 0, 0)]

        for item in items.sorted(by: { $0.priceCents > $1.priceCents }) {
            var nextBeam = beam
            for (current, total, vegCount) in beam {
                for qty in 1...maxQuantity(for: item, partySize: constraints.partySize) {
                    let nextTotal = total + item.priceCents * qty
                    if nextTotal > hardCap { continue }
                    let line = ComboLineItem(
                        menuItemId: item.id,
                        name: item.name,
                        quantity: qty,
                        unitPriceCents: item.priceCents
                    )
                    nextBeam.append((
                        current + [line],
                        nextTotal,
                        vegCount + ((item.isVegetarian || item.isVegan) ? qty : 0)
                    ))
                }
            }

            nextBeam.sort {
                let lhsClose = abs(Double(constraints.budgetCents) * 0.94 - Double($0.1))
                let rhsClose = abs(Double(constraints.budgetCents) * 0.94 - Double($1.1))
                if lhsClose != rhsClose { return lhsClose < rhsClose }
                if $0.0.count != $1.0.count { return $0.0.count > $1.0.count }
                return partialDuplicatePenalty($0.0) < partialDuplicatePenalty($1.0)
            }
            beam = dedupeStates(Array(nextBeam.prefix(maxPartialStates * 2))).prefix(maxPartialStates).map { $0 }
        }

        for (current, total, vegCount) in beam where !current.isEmpty {
            let candidate = makeCandidate(
                lineItems: current,
                total: total,
                vegCount: vegCount,
                constraints: constraints,
                itemLookup: itemLookup
            )
            if isPlausibleMeal(candidate, constraints: constraints) {
                candidates.append(candidate)
            }
        }

        let vegNeeded = constraints.vegetarianCount > 0
            ? constraints.vegetarianCount
            : (constraints.dietaryRules.contains(.vegetarian) ? 1 : 0)

        if vegNeeded > 0 {
            candidates = candidates.filter { $0.vegItemCount >= vegNeeded }
        }

        return candidates.filter { $0.itemCount >= max(1, constraints.partySize / 3) }
    }

    private static func makeCandidate(
        lineItems: [ComboLineItem],
        total: Int,
        vegCount: Int,
        constraints: Constraints,
        itemLookup: [UUID: MenuItem]
    ) -> Candidate {
        let itemCount = lineItems.reduce(0) { $0 + $1.quantity }
        let unique = Set(lineItems.map(\.menuItemId)).count
        var servingScore = 0.0
        var mainServings = 0.0
        var appetizerServings = 0.0
        var dessertServings = 0.0
        var drinkCount = 0
        var duplicatePenalty = 0.0

        for line in lineItems {
            guard let item = itemLookup[line.menuItemId] else { continue }
            let servings = estimatedServings(for: item) * Double(line.quantity)
            servingScore += servings

            switch item.course ?? .unknown {
            case .main:
                mainServings += servings
            case .appetizer, .side:
                appetizerServings += servings
            case .dessert:
                dessertServings += servings
            case .drink:
                drinkCount += line.quantity
            case .unknown:
                break
            }

            let sensible = sensibleQuantity(for: item, partySize: constraints.partySize)
            duplicatePenalty += Double(max(0, line.quantity - sensible)) * 12
        }

        if unique == 1, constraints.partySize > 1 {
            duplicatePenalty += 28
        }

        let score = scoreCandidate(
            total: total,
            budget: constraints.budgetCents,
            partySize: constraints.partySize,
            itemCount: itemCount,
            unique: unique,
            servingScore: servingScore,
            mainServings: mainServings,
            appetizerServings: appetizerServings,
            dessertServings: dessertServings,
            drinkCount: drinkCount,
            duplicatePenalty: duplicatePenalty,
            goals: constraints.optimizeGoals
        )

        return Candidate(
            lineItems: lineItems,
            totalCents: total,
            itemCount: itemCount,
            uniqueDishes: unique,
            vegItemCount: vegCount,
            servingScore: servingScore,
            mainServings: mainServings,
            appetizerServings: appetizerServings,
            dessertServings: dessertServings,
            drinkCount: drinkCount,
            duplicatePenalty: duplicatePenalty,
            score: score
        )
    }

    private static func scoreCandidate(
        total: Int,
        budget: Int,
        partySize: Int,
        itemCount: Int,
        unique: Int,
        servingScore: Double,
        mainServings: Double,
        appetizerServings: Double,
        dessertServings: Double,
        drinkCount: Int,
        duplicatePenalty: Double,
        goals: Set<OptimizeGoal>
    ) -> Double {
        let budgetScore = budgetFitScore(total: total, budget: budget)
        let coverageScore = min(servingScore / max(1.0, Double(partySize) * 0.95), 1.2) * 32
        let mainScore = min(mainServings / max(1.0, Double(partySize) * 0.75), 1.0) * 24
        let varietyScore = min(Double(unique) / Double(max(2, min(partySize, 5))), 1.0) * 16
        var completenessScore = 0.0

        if mainServings >= Double(partySize) * 0.65 { completenessScore += 12 }
        if partySize >= 2, appetizerServings > 0 { completenessScore += 6 }
        if drinkCount > 0, total >= Int(Double(budget) * 0.85) { completenessScore += 3 }
        if goals.contains(.dessertIncluded), dessertServings > 0 { completenessScore += 8 }

        var effectiveGoals = goals
        if effectiveGoals.isDisjoint(with: [.bestValue, .mostFood, .bestVariety]) {
            effectiveGoals.insert(.bestValue)
        }

        var score = budgetScore + coverageScore + mainScore + completenessScore
        if effectiveGoals.contains(.bestValue) {
            score += budgetScore * 0.35 + varietyScore * 0.35
        }
        if effectiveGoals.contains(.mostFood) {
            score += coverageScore * 0.8 + Double(itemCount) * 1.5
        }
        if effectiveGoals.contains(.bestVariety) {
            score += varietyScore * 1.2
        }
        if goals.contains(.familyStyle) {
            score += min(appetizerServings + mainServings, Double(partySize)) * 1.5
        }

        return score - duplicatePenalty
    }

    private static func budgetFitScore(total: Int, budget: Int) -> Double {
        guard budget > 0 else { return 0 }
        let utilization = Double(total) / Double(budget)
        if utilization <= 1.0 {
            if utilization < 0.55 {
                return utilization / 0.55 * 25
            }
            if utilization < 0.85 {
                return 25 + (utilization - 0.55) / 0.30 * 35
            }
            return 60 + max(0, 1 - abs(0.96 - utilization) / 0.11) * 40
        }
        if utilization <= 1.10 {
            return 48 - (utilization - 1.0) / 0.10 * 35
        }
        return -100
    }

    private static func isPlausibleMeal(_ candidate: Candidate, constraints: Constraints) -> Bool {
        if Double(candidate.totalCents) > Double(constraints.budgetCents) * 1.12 { return false }
        if candidate.mainServings <= 0, candidate.appetizerServings <= 0 { return false }
        if candidate.servingScore < max(0.75, Double(constraints.partySize) * 0.55) { return false }
        if candidate.uniqueDishes == 1, constraints.partySize >= 3 {
            return candidate.servingScore >= Double(constraints.partySize) * 0.9
        }
        return true
    }

    private static func estimatedServings(for item: MenuItem) -> Double {
        if let servesMax = item.servesMax, servesMax > 1 { return Double(servesMax) }
        if item.isShareable == true { return 2.0 }
        switch item.course ?? .unknown {
        case .main:
            return 1.0
        case .appetizer, .side:
            return 0.6
        case .dessert:
            return 0.45
        case .drink:
            return 0.1
        case .unknown:
            return 0.75
        }
    }

    private static func maxQuantity(for item: MenuItem, partySize: Int) -> Int {
        switch item.course ?? .unknown {
        case .drink:
            return min(max(partySize, 2), 8)
        case .dessert:
            return min(max(partySize / 2 + 1, 2), 5)
        case .main:
            if item.isShareable == true || (item.servesMax ?? 1) > 1 {
                let serves = max(item.servesMax ?? 1, 1)
                return min(max((partySize + serves - 1) / serves + 1, 2), 5)
            }
            return min(max(partySize, 2), 6)
        case .appetizer, .side, .unknown:
            if item.isShareable == true || (item.servesMax ?? 1) > 1 {
                let serves = max(item.servesMax ?? 1, 1)
                return min(max((partySize + serves - 1) / serves + 1, 2), 5)
            }
            return min(max(partySize / 2 + 2, 2), 5)
        }
    }

    private static func sensibleQuantity(for item: MenuItem, partySize: Int) -> Int {
        if item.course == .drink { return partySize }
        if item.isShareable == true || (item.servesMax ?? 1) > 1 {
            let serves = max(item.servesMax ?? 1, 1)
            return max(1, (partySize + serves - 1) / serves)
        }
        if item.course == .main { return max(1, partySize) }
        return max(1, partySize / 2 + 1)
    }

    private static func partialDuplicatePenalty(_ lineItems: [ComboLineItem]) -> Int {
        lineItems.reduce(0) { $0 + max(0, $1.quantity - 2) }
    }

    private static func dedupeStates(_ states: [([ComboLineItem], Int, Int)]) -> [([ComboLineItem], Int, Int)] {
        var seen = Set<String>()
        var unique: [([ComboLineItem], Int, Int)] = []
        for state in states {
            let signature = state.0
                .map { "\($0.menuItemId.uuidString)-\($0.quantity)" }
                .sorted()
                .joined(separator: "|")
            if seen.contains(signature) { continue }
            seen.insert(signature)
            unique.append(state)
        }
        return unique
    }

    private static func referenceSpendCents(partySize: Int, items: [MenuItem]) -> Int {
        guard !items.isEmpty else { return 0 }
        let sorted = items.map(\.priceCents).sorted()
        let median = sorted[sorted.count / 2]
        return median * partySize
    }

    private static func isTooSimilar(_ a: Candidate, to b: Candidate) -> Bool {
        let aIds = Set(a.lineItems.map(\.menuItemId))
        let bIds = Set(b.lineItems.map(\.menuItemId))
        let overlap = aIds.intersection(bIds).count
        let union = max(1, aIds.union(bIds).count)
        return Double(overlap) / Double(union) > 0.72
    }

    private static func isDiverse(_ candidate: Candidate, against others: [Candidate]) -> Bool {
        others.allSatisfy { !isTooSimilar($0, to: candidate) }
    }

    private static func comboMetadata(
        rank: Int,
        candidate: Candidate,
        constraints: Constraints,
        referenceSpend: Int
    ) -> (title: String, subtitle: String) {
        let overBudget = candidate.totalCents > constraints.budgetCents
        let underBudget = candidate.totalCents < Int(Double(constraints.budgetCents) * 0.85)

        switch rank {
        case 1:
            let spend = Double(candidate.totalCents) / Double(max(1, constraints.budgetCents))
            let title = spend >= 0.85 ? "The Crowd Pleaser" : "Smart Under-Budget Pick"
            let subtitlePrefix = spend >= 0.85 ? "Full spread" : "Complete meal"
            return (
                title,
                "\(subtitlePrefix) for \(constraints.partySize) people · \(constraints.vegetarianCount > 0 ? "\(constraints.vegetarianCount) vegetarian" : "balanced picks")"
            )
        case 2:
            return (
                "The Feast",
                overBudget ? "More food, slightly over — worth it?" : "Hearty portions for the group"
            )
        case 3:
            return (
                "Light & Fresh",
                underBudget ? "Under budget, leaves room for dessert." : "Lighter spread, great variety"
            )
        default:
            return ("Combo \(rank)", "Curated for your group")
        }
    }

    private static func buildSummary(combos: [Combo], constraints: Constraints) -> String {
        var parts: [String] = ["Found \(combos.count) combos"]
        if constraints.dietaryRules.contains(.noFish) { parts.append("that skip fish") }
        if constraints.vegetarianCount > 0 {
            parts.append("and cover both vegetarians")
        }
        if let first = combos.first, first.totalCents <= constraints.budgetCents {
            parts.append("Pick #1 to stay under budget.")
        }
        return parts.joined(separator: " ") + "."
    }

    private static func buildConstraintTags(constraints: Constraints) -> [String] {
        var tags = ["Party of \(constraints.partySize)", "\(constraints.budgetFormatted) max"]
        for rule in constraints.dietaryRules.sorted(by: { $0.label < $1.label }) {
            tags.append(rule.label)
        }
        if constraints.vegetarianCount > 1 {
            tags.append("Vegetarian x\(constraints.vegetarianCount)")
        }
        return tags
    }
}
