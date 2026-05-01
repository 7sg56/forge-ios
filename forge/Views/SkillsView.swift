import SwiftUI
import SwiftData

struct SkillsView: View {
    @Environment(\.modelContext) private var context
    @Query var allSkills: [SkillTrack]

    @State private var showingAdd = false
    @State private var appeared = false

    var activeSkills: [SkillTrack] {
        allSkills.filter { $0.status == .active }
    }
    var practicingSkills: [SkillTrack] {
        allSkills.filter { $0.status == .practicing }
    }
    var queuedSkills: [SkillTrack] {
        allSkills.filter { $0.status == .queued }
    }
    var acquiredSkills: [SkillTrack] {
        allSkills.filter { $0.status == .acquired }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(tint: Color(red: 0.1, green: 0.04, blue: 0.02))

                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SKILL FORGE")
                                    .font(.system(size: 28, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("level up or fall behind")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.2))
                            }
                            Spacer()
                        }

                        HStack(spacing: 6) {
                            ForEach(0..<2, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i < activeSkills.count
                                          ? Color(red: 1.0, green: 0.5, blue: 0.2).opacity(0.7)
                                          : Color.white.opacity(0.08))
                                    .frame(width: 24, height: 4)
                            }
                            Text("ACTIVE \(activeSkills.count)/2")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.25))
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            if allSkills.isEmpty {
                                // Empty state
                                VStack(spacing: 16) {
                                    Image(systemName: "flame")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.2).opacity(0.15))
                                    Text("// no skills tracked yet")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.15))
                                    Text("Activate to start tracking progress.\nWhat are you learning right now?")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.08))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(3)

                                    Button {
                                        Haptic.medium()
                                        showingAdd = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 11, weight: .bold))
                                            Text("ADD YOUR FIRST SKILL")
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        }
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color(red: 1.0, green: 0.5, blue: 0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .padding(.top, 8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            } else {
                                if !activeSkills.isEmpty {
                                    skillSection("ACTIVELY LEARNING", skills: activeSkills, startIndex: 0)
                                }
                                if !practicingSkills.isEmpty {
                                    skillSection("PRACTICING", skills: practicingSkills, startIndex: activeSkills.count)
                                }
                                if !queuedSkills.isEmpty {
                                    skillSection("QUEUED", skills: queuedSkills, startIndex: activeSkills.count + practicingSkills.count)
                                }
                                if !acquiredSkills.isEmpty {
                                    skillSection("ACQUIRED", skills: acquiredSkills, startIndex: activeSkills.count + practicingSkills.count + queuedSkills.count)
                                }
                            }

                            Button {
                                Haptic.medium()
                                showingAdd = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("NEW SKILL")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.white.opacity(0.3))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [8, 6]))
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .onAppear { appeared = true }
            .sheet(isPresented: $showingAdd) {
                AddSkillSheet()
            }
            .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    func skillSection(_ title: String, skills: [SkillTrack], startIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: title)
                .padding(.horizontal, 20)

            ForEach(Array(skills.enumerated()), id: \.element.id) { index, skill in
                NavigationLink(destination: SkillDetailView(skill: skill)) {
                    SkillCard(skill: skill)
                }
                .buttonStyle(CardPressStyle())
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8).delay(Double(startIndex + index) * 0.08),
                    value: appeared
                )
            }
        }
    }
}

// MARK: - Skill Card

struct SkillCard: View {
    let skill: SkillTrack

    var accent: Color { skillCategoryColor(skill.category) }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 4)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(skill.name.uppercased())
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    SkillCategoryBadge(category: skill.category)
                }

                HStack {
                    SkillStatusPill(status: skill.status)
                    Spacer()
                    HStack(spacing: 6) {
                        ProgressArc(progress: skill.progress, size: 20, color: accent)
                        Text("\(Int(skill.progress * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                if let target = skill.targetDate {
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: target).day ?? 0
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 9))
                        Text(days <= 0 ? "PAST DUE" : "\(days) days to target")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(days <= 7 ? .red.opacity(0.6) : .white.opacity(0.2))
                }

                if !skill.linkedProjectName.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 8))
                        Text("supports \(skill.linkedProjectName.uppercased())")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(Color(red: 0.75, green: 0.5, blue: 1.0).opacity(0.5))
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.035))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accent.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: accent.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, 20)
    }
}

// MARK: - Add Skill Sheet

struct AddSkillSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: SkillCategory = .certification
    @State private var notes = ""
    @State private var hasTarget = false
    @State private var targetDate = Date().addingTimeInterval(30 * 24 * 3600)

    var body: some View {
        ZStack {
            AppBackground(tint: Color(red: 0.06, green: 0.03, blue: 0.08))

            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("NEW SKILL")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(10)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 36)

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "SKILL NAME")
                    TextField("AWS Solutions Architect, Rust, etc.", text: $name)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "CATEGORY")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SkillCategory.allCases, id: \.self) { cat in
                                Button {
                                    Haptic.light()
                                    category = cat
                                } label: {
                                    Text(cat.rawValue.uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(category == cat ? .black : .white.opacity(0.3))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(category == cat ? skillCategoryColor(cat) : Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .animation(.spring(response: 0.3), value: category)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "NOTES (OPTIONAL)")
                    TextField("resources, plan, motivation...", text: $notes, axis: .vertical)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(3, reservesSpace: true)
                        .padding(14)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $hasTarget) {
                        SectionLabel(text: "TARGET DATE")
                    }
                    .tint(Color(red: 1.0, green: 0.5, blue: 0.2))

                    if hasTarget {
                        DatePicker("", selection: $targetDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                    }
                }

                Spacer()

                Button {
                    guard !name.isEmpty else {
                        Haptic.warning()
                        return
                    }
                    Haptic.success()
                    let skill = SkillTrack(
                        name: name,
                        category: category,
                        notes: notes,
                        targetDate: hasTarget ? targetDate : nil
                    )
                    context.insert(skill)
                    dismiss()
                } label: {
                    Text("FORGE IT")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.5, blue: 0.2), Color(red: 1.0, green: 0.4, blue: 0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
}
