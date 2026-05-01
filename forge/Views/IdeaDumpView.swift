import SwiftUI
import SwiftData

struct IdeaDumpView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AIService.self) private var aiService

    @State private var rawText = ""
    @State private var result: BrainDumpResult?
    @State private var isProcessing = false
    @State private var errorMsg: String?
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppBackground(tint: Color(red: 0.04, green: 0.06, blue: 0.12))

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        if result == nil {
                            inputSection
                        } else {
                            resultsSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: appeared)
        }
        .onAppear { appeared = true }
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
                        colors: [Color(red: 0.4, green: 0.8, blue: 1.0), Color(red: 0.3, green: 0.6, blue: 0.9)],
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
                    dumpCategory("PROJECTS", items: r.projects, color: .white, icon: "hammer.fill") { item in
                        addProject(item)
                    }
                }

                if !r.skills.isEmpty {
                    dumpCategory("SKILLS", items: r.skills, color: Color(red: 1.0, green: 0.5, blue: 0.2), icon: "flame.fill") { item in
                        addSkill(item)
                    }
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
                        dismiss()
                    } label: {
                        Text("ADD ALL")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.4, green: 0.8, blue: 1.0))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
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
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 3)
                        .padding(.vertical, 6)

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
                        Button {
                            Haptic.light()
                            action(item)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(color.opacity(0.6))
                        }
                        .buttonStyle(ScaleButtonStyle())
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
        let priority: Priority = {
            switch item.suggestedPriority?.lowercased() {
            case "high":   return .high
            case "low":    return .low
            default:       return .medium
            }
        }()
        let p = Project(name: item.name, tagline: item.reason, priority: priority)
        context.insert(p)
        Haptic.success()
    }

    func addSkill(_ item: BrainDumpItem) {
        let s = SkillTrack(name: item.name, category: .other, notes: item.reason)
        context.insert(s)
        Haptic.success()
    }

    func addAll() {
        guard let r = result else { return }
        for item in r.projects { addProject(item) }
        for item in r.skills { addSkill(item) }
    }
}
