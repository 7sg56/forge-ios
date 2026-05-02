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
                AppBackground()

                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SKILL FORGE")
                                    .font(.system(size: 24, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                    .tracking(2)
                                Text("// Currently tracking \(allSkills.count) objectives")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            Spacer()
                            Button {
                                Haptic.medium()
                                showingAdd = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12))
                                    Text("ADD SKILL")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black)
                                .overlay(
                                    Rectangle().stroke(Color(white: 0.25), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }

                        HStack(spacing: 6) {
                            ForEach(0..<2, id: \.self) { i in
                                Rectangle()
                                    .fill(i < activeSkills.count
                                          ? Color(red: 0.4, green: 0.8, blue: 1.0) // primary-container
                                          : Color(white: 0.13))
                                    .frame(width: 24, height: 4)
                            }
                            Text("ACTIVE \(activeSkills.count)/2")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 24)
                    .background(Color.black)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            if allSkills.isEmpty {
                                // Empty state
                                VStack(spacing: 16) {
                                    Image(systemName: "flame")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.15))
                                    Text("// no skills tracked yet")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.3))
                                    Text("Activate to start tracking progress.\nWhat are you learning right now?")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.2))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(4)
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
                        }
                        .padding(.top, 12)
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
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: title)
                .padding(.horizontal, 20)

            ForEach(Array(skills.enumerated()), id: \.element.id) { index, skill in
                NavigationLink(destination: SkillDetailView(skill: skill)) {
                    SkillCard(skill: skill)
                }
                .buttonStyle(CardPressStyle())
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8).delay(Double(startIndex + index) * 0.06),
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
        VStack(spacing: 0) {
            // Top Section
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(accent)
                            .frame(width: 8, height: 8)
                        Text(skill.category.rawValue.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                    }
                    Text(skill.name)
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(.white)
                }
                Spacer()
                
                HStack(spacing: 4) {
                    if skill.status == .active {
                        Circle()
                            .fill(accent)
                            .frame(width: 6, height: 6)
                            .modifier(PulseEffect())
                    }
                    Text(skill.status.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(accent)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black)
                .border(accent, width: 1)
            }
            .padding(16)
            
            // Bottom Section
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TARGET: \(skill.status == .acquired ? "ACQUIRED" : "MASTERY")")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                    
                    if let target = skill.targetDate {
                        let days = Calendar.current.dateComponents([.day], from: Date(), to: target).day ?? 0
                        Text(days <= 0 ? "Past Due" : "\(days)d Remaining")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(days <= 7 ? Color(red: 1.0, green: 0.27, blue: 0.27) : .white)
                    } else {
                        Text("Continuous")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                
                // Progress Arc inside the box
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.15), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: CGFloat(skill.progress))
                        .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .square))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(skill.progress * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
            }
            .padding(16)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(white: 0.13)),
                alignment: .top
            )
        }
        .background(
            ZStack {
                Color.black
                LinearGradient(
                    colors: [accent.opacity(0.05), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            Rectangle()
                .stroke(Color(white: 0.13), lineWidth: 1)
        )
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
            AppBackground()

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
