import SwiftUI
import SwiftData

struct IdeaDumpView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AIService.self) private var aiService

    @Query var allProjects: [Project]
    @Query var allSkills: [SkillTrack]

    @State private var rawText = ""
    @State private var result: BrainDumpResult?
    @State private var isProcessing = false
    @State private var errorMsg: String?
    @State private var appeared = false
    @State private var showCapAlert = false
    @State private var capAlertMessage = ""
    @State private var scrollProxy: ScrollViewProxy?
    @State private var addedItems: Set<String> = []

    var activeProjects: [Project] {
        allProjects.filter { $0.status != .killed }
    }

    var activeSkillCount: Int {
        allSkills.filter { $0.status == .active }.count
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .padding(.bottom, 20)

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            if result == nil {
                                inputSection
                            } else {
                                resultsSection
                                    .id("results")
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                    .onChange(of: result) {
                        if result != nil {
                            withAnimation(.easeOut(duration: 0.4)) {
                                proxy.scrollTo("results", anchor: .top)
                            }
                        }
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: appeared)
        }
        .onAppear { appeared = true }
        .alert("Capacity Reached", isPresented: $showCapAlert) {
            Button("GOT IT") { }
        } message: {
            Text(capAlertMessage)
        }
    }

    // MARK: - Header

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("BRAIN DUMP")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text("dump everything, AI sorts it")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.2))
            }
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
    }

    // MARK: - Input

    var inputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "RAW IDEAS")
                Text("Type every idea, certification, skill, tool, project -- one per line. Don't filter yourself.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.25))
                    .lineSpacing(3)
            }

            TextField("iOS weather app\nAWS Solutions Architect\nlearn Rust\nbudget tracker\nKubernetes\nportfolio website\n...", text: $rawText, axis: .vertical)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(12, reservesSpace: true)
                .padding(16)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )

            if let err = errorMsg {
                Text(err)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.red.opacity(0.6))
            }

            Button {
                Haptic.medium()
                processDump()
            } label: {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.black)
                    } else {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(isProcessing ? "SORTING..." : "AI SORT")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.white, Color(white: 0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            .opacity(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
        }
    }

    // MARK: - Results

    var resultsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let r = result {
                if !r.projects.isEmpty {
                    projectResults(r.projects)
                }

                if !r.skills.isEmpty {
                    skillResults(r.skills)
                }

                if !r.ignore.isEmpty {
                    dumpCategory("IGNORED", items: r.ignore, color: .red.opacity(0.5), icon: "trash", action: nil)
                }

                SubtleDivider()

                HStack(spacing: 12) {
                    Button {
                        Haptic.medium()
                        result = nil
                        rawText = ""
                    } label: {
                        Text("DUMP AGAIN")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        Haptic.success()
                        addAll()
                    } label: {
                        Text("ADD ALL")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    // MARK: - Project Results (with AI verdict inline)

    @ViewBuilder
    func projectResults(_ items: [BrainDumpItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 10, weight: .bold))
                SectionLabel(text: "PROJECTS (\(items.count))")
            }
            .foregroundColor(.white)

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(verdictColor(item.verdict))
                            .frame(width: 3)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(item.name.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()

                                // Verdict badge
                                if let verdict = item.verdict, !verdict.isEmpty {
                                    Text(verdict)
                                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                        .foregroundColor(verdictColor(item.verdict))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(verdictColor(item.verdict).opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                }
                            }

                            Text(item.reason)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.35))
                                .lineLimit(2)

                            // Pros & Cons
                            if let pro = item.pro, !pro.isEmpty {
                                HStack(alignment: .top, spacing: 4) {
                                    Text("+")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(red: 0.3, green: 0.9, blue: 0.4))
                                    Text(pro)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.3))
                                        .lineLimit(1)
                                }
                            }
                            if let con = item.con, !con.isEmpty {
                                HStack(alignment: .top, spacing: 4) {
                                    Text("-")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.red.opacity(0.7))
                                    Text(con)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.3))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 12)
                        .padding(.vertical, 10)

                        // Add button
                        let isAdded = addedItems.contains("project:\(item.name)")
                        Button {
                            Haptic.light()
                            addProject(item)
                        } label: {
                            Text(isAdded ? "ADDED" : "+ ADD")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .foregroundColor(isAdded ? Color(red: 0.3, green: 0.9, blue: 0.4).opacity(0.6) : .white.opacity(0.5))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isAdded ? Color(red: 0.3, green: 0.9, blue: 0.4).opacity(0.08) : Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(isAdded)
                        .padding(.trailing, 12)
                    }
                }
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Skill Results

    @ViewBuilder
    func skillResults(_ items: [BrainDumpItem]) -> some View {
        dumpCategory("SKILLS", items: items, color: Color(red: 1.0, green: 0.7, blue: 0.2), icon: "flame.fill") { item in
            addSkill(item)
        }
    }

    @ViewBuilder
    func dumpCategory(_ title: String, items: [BrainDumpItem], color: Color, icon: String, action: ((BrainDumpItem) -> Void)?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                SectionLabel(text: "\(title) (\(items.count))")
            }
            .foregroundColor(color)

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(color)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text(item.reason)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.35))
                            .lineLimit(2)
                    }
                    .padding(.leading, 10)

                    Spacer()

                    if let action = action {
                        let isAdded = addedItems.contains("skill:\(item.name)")
                        Button {
                            Haptic.light()
                            action(item)
                        } label: {
                            Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(isAdded ? Color(red: 0.3, green: 0.9, blue: 0.4).opacity(0.6) : color.opacity(0.6))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(isAdded)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(color.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.1), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Actions

    func processDump() {
        isProcessing = true
        errorMsg = nil
        Task {
            do {
                let r = try await aiService.batchSortIdeas(rawText: rawText)
                result = r
            } catch {
                errorMsg = error.localizedDescription
            }
            isProcessing = false
        }
    }

    func addProject(_ item: BrainDumpItem) {
        let key = "project:\(item.name)"
        guard !addedItems.contains(key) else { return }

        // Capacity gate: block if 3+ active projects
        guard activeProjects.count < 3 else {
            capAlertMessage = "Kill or ship something first. You already have 3 active projects."
            showCapAlert = true
            Haptic.warning()
            return
        }

        let priority: Priority = {
            switch item.suggestedPriority?.lowercased() {
            case "high":   return .high
            case "low":    return .low
            default:       return .medium
            }
        }()
        let p = Project(name: item.name, tagline: item.reason, priority: priority)
        context.insert(p)
        addedItems.insert(key)
        Haptic.success()
    }

    func addSkill(_ item: BrainDumpItem) {
        let key = "skill:\(item.name)"
        guard !addedItems.contains(key) else { return }

        // Skills start as queued, so no active cap issue on add.
        // Cap is enforced when activating (in SkillDetailView).
        let s = SkillTrack(name: item.name, category: .other, notes: item.reason)
        context.insert(s)
        addedItems.insert(key)
        Haptic.success()
    }

    func addAll() {
        guard let r = result else { return }
        // Prevent double-tapping ADD ALL
        guard addedItems.isEmpty || addedItems.count < (r.projects.count + r.skills.count) else { return }

        var addedProjects = 0
        let projectSlots = max(0, 3 - activeProjects.count)

        for item in r.projects {
            let key = "project:\(item.name)"
            guard !addedItems.contains(key) else { continue }

            if addedProjects >= projectSlots {
                capAlertMessage = "Reached 3-project cap. Some projects were skipped."
                showCapAlert = true
                break
            }
            let priority: Priority = {
                switch item.suggestedPriority?.lowercased() {
                case "high":   return .high
                case "low":    return .low
                default:       return .medium
                }
            }()
            let p = Project(name: item.name, tagline: item.reason, priority: priority)
            context.insert(p)
            addedItems.insert(key)
            addedProjects += 1
        }

        for item in r.skills {
            let key = "skill:\(item.name)"
            guard !addedItems.contains(key) else { continue }
            let s = SkillTrack(name: item.name, category: .other, notes: item.reason)
            context.insert(s)
            addedItems.insert(key)
        }

        if !showCapAlert {
            dismiss()
        }
    }

    func verdictColor(_ verdict: String?) -> Color {
        switch verdict?.uppercased() {
        case "WORTH BUILDING":   return Color(red: 0.3, green: 0.9, blue: 0.4)
        case "NEEDS THOUGHT":    return Color(red: 1.0, green: 0.7, blue: 0.2)
        case "KILL IT":          return .red
        default:                 return .white.opacity(0.3)
        }
    }
}
