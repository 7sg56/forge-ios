import SwiftUI
import UIKit
import Foundation
import SwiftData

// MARK: - Haptics
enum Haptic {
    static func light()   { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()  { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy()   { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error()   { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}

// MARK: - Colors
func priorityColor(_ p: Priority) -> Color {
    switch p {
    case .high:   return Color(red: 1.0, green: 0.27, blue: 0.27)  // red
    case .medium: return Color(red: 1.0, green: 0.7, blue: 0.2)    // amber
    case .low:    return Color(red: 0.35, green: 0.55, blue: 1.0)   // blue
    }
}

func statusColor(_ s: ProjectStatus) -> Color {
    switch s {
    case .ideating:   return Color(red: 1.0, green: 0.84, blue: 0.2)
    case .validating: return Color(red: 0.75, green: 0.5, blue: 1.0)
    case .building:   return Color(red: 0.2, green: 0.85, blue: 0.9)
    case .shipped:    return Color(red: 0.3, green: 0.9, blue: 0.4)
    case .killed:     return Color(red: 1.0, green: 0.27, blue: 0.27)
    }
}

func skillCategoryColor(_ c: SkillCategory) -> Color {
    switch c {
    case .certification: return Color(red: 1.0, green: 0.84, blue: 0.2)
    case .language:      return Color(red: 0.35, green: 0.55, blue: 1.0)
    case .framework:     return Color(red: 0.75, green: 0.5, blue: 1.0)
    case .devops:        return Color(red: 0.2, green: 0.85, blue: 0.9)
    case .softSkill:     return Color(red: 1.0, green: 0.6, blue: 0.7)
    case .design:        return Color(red: 1.0, green: 0.5, blue: 0.2)
    case .other:         return Color.white.opacity(0.5)
    }
}

// MARK: - Button Styles
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Pulse Modifier
struct PulseEffect: ViewModifier {
    @State private var pulse = false
    func body(content: Content) -> some View {
        content
            .opacity(pulse ? 0.35 : 1.0)
            .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}

// MARK: - App Background
struct AppBackground: View {
    var body: some View {
        Color.black
            .ignoresSafeArea()
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: Priority
    var color: Color { priorityColor(priority) }

    var body: some View {
        Text(priority.rawValue.uppercased())
            .font(.system(size: 9, weight: .heavy, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color.opacity(0.2), lineWidth: 0.5)
            )
    }
}

// MARK: - Status Pill
struct StatusPill: View {
    let status: ProjectStatus

    var color: Color { statusColor(status) }

    var body: some View {
        HStack(spacing: 5) {
            if status != .shipped && status != .killed {
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                    .modifier(PulseEffect())
            }
            Text(status.rawValue.uppercased())
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Status Pipeline (visual dots + lines)
struct StatusPipeline: View {
    let currentStatus: ProjectStatus
    var onSelect: ((ProjectStatus) -> Void)? = nil

    private let stages: [ProjectStatus] = [.ideating, .validating, .building, .shipped]

    private var currentIndex: Int {
        stages.firstIndex(of: currentStatus) ?? 0
    }

    var body: some View {
        VStack(spacing: 14) {
            // Dots and connecting lines
            HStack(spacing: 0) {
                ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                    Button {
                        onSelect?(stage)
                    } label: {
                        ZStack {
                            if index <= currentIndex {
                                Circle()
                                    .fill(statusColor(stage))
                                    .frame(width: 14, height: 14)
                                    .shadow(color: statusColor(stage).opacity(0.5), radius: index == currentIndex ? 8 : 0)

                                if index == currentIndex {
                                    Circle()
                                        .stroke(statusColor(stage).opacity(0.35), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                        .modifier(PulseEffect())
                                }
                            } else {
                                Circle()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                                    .frame(width: 14, height: 14)
                            }
                        }
                        .frame(width: 30, height: 30)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    if index < stages.count - 1 {
                        Rectangle()
                            .fill(
                                index < currentIndex
                                    ? statusColor(stages[index]).opacity(0.5)
                                    : Color.white.opacity(0.06)
                            )
                            .frame(height: 2)
                    }
                }
            }

            // Labels
            HStack(spacing: 0) {
                ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                    Text(shortLabel(stage))
                        .font(.system(size: 8, weight: index == currentIndex ? .heavy : .medium, design: .monospaced))
                        .foregroundColor(index <= currentIndex ? statusColor(stage) : Color.white.opacity(0.2))
                        .frame(width: 30)

                    if index < stages.count - 1 {
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStatus)
    }

    func shortLabel(_ s: ProjectStatus) -> String {
        switch s {
        case .ideating:   return "IDEA"
        case .validating: return "VALID"
        case .building:   return "BUILD"
        case .shipped:    return "SHIP"
        case .killed:     return "KILL"
        }
    }
}

// MARK: - Subtle Divider
struct SubtleDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.07), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

// MARK: - Section Label
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.white.opacity(0.3))
            .tracking(2)
    }
}
