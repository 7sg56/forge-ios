import SwiftUI
import SwiftData

struct SkillDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var skill: SkillTrack

    var accent: Color { skillCategoryColor(skill.category) }

    var body: some View {
        ZStack {
            AppBackground(tint: Color(red: 0.06, green: 0.03, blue: 0.08))

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SkillCategoryBadge(category: skill.category)
                            Spacer()
                            Text(skillDaysAgo())
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.2))
                        }
                        Text(skill.name.uppercased())
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    SubtleDivider()

                    // Progress Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionLabel(text: "PROGRESS")

                        HStack(spacing: 20) {
                            ProgressArc(progress: skill.progress, size: 56, color: accent)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(skill.progress * 100))%")
                                    .font(.system(size: 28, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("self-assessed")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.2))
                            }

                            Spacer()
                        }

                        Slider(value: $skill.progress, in: 0...1, step: 0.05)
                            .tint(accent)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.025))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                    )

                    SubtleDivider()

                    // Status Pipeline
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel(text: "STATUS")
                        SkillPipeline(currentStatus: skill.status) { newStatus in
                            Haptic.medium()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                skill.status = newStatus
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.025))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                    )

                    SubtleDivider()

                    // Category selector
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "CATEGORY")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SkillCategory.allCases, id: \.self) { cat in
                                    Button {
                                        Haptic.light()
                                        withAnimation(.spring(response: 0.3)) {
                                            skill.category = cat
                                        }
                                    } label: {
                                        Text(cat.rawValue.uppercased())
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(skill.category == cat ? .black : .white.opacity(0.3))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(skill.category == cat ? accent : Color.white.opacity(0.04))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                    }

                    SubtleDivider()

                    // Notes
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "NOTES")
                        TextField("resources, study plan, motivation...", text: $skill.notes, axis: .vertical)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(6, reservesSpace: true)
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                    }

                    SubtleDivider()

                    // Info row
                    HStack {
                        InfoChip(label: "STARTED", value: skill.createdAt.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        if let target = skill.targetDate {
                            InfoChip(label: "TARGET", value: target.formatted(date: .abbreviated, time: .omitted))
                        }
                    }

                    if skill.status == .acquired {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(Color(red: 0.3, green: 0.9, blue: 0.4))
                            Text("SKILL ACQUIRED")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.3, green: 0.9, blue: 0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.3, green: 0.9, blue: 0.4).opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        Haptic.error()
                        context.delete(skill)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                            Text("DELETE SKILL")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.red.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red.opacity(0.1), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 60)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    func skillDaysAgo() -> String {
        let days = Calendar.current.dateComponents([.day], from: skill.createdAt, to: Date()).day ?? 0
        if days == 0 { return "today" }
        if days == 1 { return "1 day ago" }
        return "\(days) days ago"
    }
}

// MARK: - Skill Pipeline

struct SkillPipeline: View {
    let currentStatus: SkillStatus
    var onSelect: ((SkillStatus) -> Void)? = nil

    private let stages: [SkillStatus] = [.queued, .active, .practicing, .acquired]

    private var currentIndex: Int {
        stages.firstIndex(of: currentStatus) ?? 0
    }

    func stageColor(_ s: SkillStatus) -> Color {
        switch s {
        case .queued:     return Color(red: 0.5, green: 0.5, blue: 0.6)
        case .active:     return Color(red: 0.2, green: 0.85, blue: 0.9)
        case .practicing: return Color(red: 0.75, green: 0.5, blue: 1.0)
        case .acquired:   return Color(red: 0.3, green: 0.9, blue: 0.4)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                    Button {
                        onSelect?(stage)
                    } label: {
                        ZStack {
                            if index <= currentIndex {
                                Circle()
                                    .fill(stageColor(stage))
                                    .frame(width: 14, height: 14)
                                    .shadow(color: stageColor(stage).opacity(0.5), radius: index == currentIndex ? 8 : 0)

                                if index == currentIndex {
                                    Circle()
                                        .stroke(stageColor(stage).opacity(0.35), lineWidth: 2)
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
                                    ? stageColor(stages[index]).opacity(0.5)
                                    : Color.white.opacity(0.06)
                            )
                            .frame(height: 2)
                    }
                }
            }

            HStack(spacing: 0) {
                ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                    Text(shortLabel(stage))
                        .font(.system(size: 8, weight: index == currentIndex ? .heavy : .medium, design: .monospaced))
                        .foregroundColor(index <= currentIndex ? stageColor(stage) : Color.white.opacity(0.2))
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

    func shortLabel(_ s: SkillStatus) -> String {
        switch s {
        case .queued:     return "QUEUE"
        case .active:     return "LEARN"
        case .practicing: return "PRACT"
        case .acquired:   return "DONE"
        }
    }
}
