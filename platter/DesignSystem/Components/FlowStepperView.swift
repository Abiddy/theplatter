import SwiftUI

enum FlowStep: Int, CaseIterable {
    case scan = 1
    case preferences = 2
    case results = 3

    var label: String {
        switch self {
        case .scan: "Scan"
        case .preferences: "Preferences"
        case .results: "Results"
        }
    }

    var icon: String {
        switch self {
        case .scan: "viewfinder"
        case .preferences: "slider.horizontal.3"
        case .results: "sparkles"
        }
    }
}

struct FlowStepperView: View {
    let currentStep: FlowStep

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(FlowStep.allCases.enumerated()), id: \.element) { index, step in
                HStack(spacing: 0) {
                    stepNode(step)

                    if index < FlowStep.allCases.count - 1 {
                        connector(after: step)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func stepNode(_ step: FlowStep) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(circleFill(for: step))
                    .frame(width: 32, height: 32)

                if step.rawValue < currentStep.rawValue {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: step.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(stepIconColor(for: step))
                }
            }

            Text(step.label)
                .font(PlatterFont.caption(12))
                .foregroundStyle(labelColor(for: step))
        }
        .frame(maxWidth: .infinity)
    }

    private func connector(after step: FlowStep) -> some View {
        Rectangle()
            .fill(step.rawValue < currentStep.rawValue ? PlatterColors.stepComplete : PlatterColors.divider)
            .frame(width: 24, height: 2)
            .offset(y: -10)
    }

    private func circleFill(for step: FlowStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            PlatterColors.stepComplete
        } else if step.rawValue == currentStep.rawValue {
            PlatterColors.brandOrange
        } else {
            PlatterColors.inactiveFill
        }
    }

    private func stepIconColor(for step: FlowStep) -> Color {
        step.rawValue == currentStep.rawValue ? .white : PlatterColors.textTertiary
    }

    private func labelColor(for step: FlowStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            PlatterColors.textPrimary
        } else if step.rawValue == currentStep.rawValue {
            PlatterColors.brandOrange
        } else {
            PlatterColors.textTertiary
        }
    }
}
