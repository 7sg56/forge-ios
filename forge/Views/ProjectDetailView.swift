import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AIService.self) private var aiService

    @Bindable var project: Project

    @State private var showingKillSheet = false
    @State private var newTag = ""
    @State private var showDatePicker = false

    // AI Kill Recommendation
    @State private var killRec: KillRecommendation?
    @State private var isLoadingKillRec = false
    @State private var killRecError: String?

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    // Name + priority header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            PriorityBadge(priority: project.priority)
                            Spacer()
                            Text(daysAgo())
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.2))
                        }
                        Text(project.name.uppercased())
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        if !project.tagline.isEmpty {
                            Text(project.tagline)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.white.opacity(0.35))
                        }
                    }

                    SubtleDivider()

                    // Status Pipeline (visual)
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "PIPELINE")
                        StatusPipeline(currentStatus: project.status) { newStatus in
                            Haptic.medium()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                project.status = newStatus
                                project.lastUpdatedAt = Date()
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

                    // Priority selector
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "PRIORITY")
                        HStack(spacing: 10) {
                            ForEach(Priority.allCases, id: \.self) { p in
                                Button {
                                    Haptic.light()
                                    withAnimation(.spring(response: 0.3)) {
                                        project.priority = p
                                        project.lastUpdatedAt = Date()
                                    }
                                } label: {
                                    Text(p.rawValue.uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(project.priority == p ? .black : .white.opacity(0.3))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 9)
                                        .background(project.priority == p ? priorityColor(p) : Color.white.opacity(0.04))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(
                                                    project.priority == p ? Color.clear : Color.white.opacity(0.06),
                                                    lineWidth: 0.5
                                                )
                                        )
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }

                    SubtleDivider()

                    // MARK: - Deadline
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SectionLabel(text: "DEADLINE")
                            Spacer()
                            if project.deadline != nil {
                                Button {
                                    Haptic.light()
                                    project.deadline = nil
                                    NotificationService.cancelNotifications(for: project.id)
                                } label: {
                                    Text("CLEAR")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.red.opacity(0.5))
                                }
                            }
                        }

                        if let deadline = project.deadline {
                            let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
                            HStack(spacing: 10) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                    .foregroundColor(days <= 7 ? .red.opacity(0.7) : .white.opacity(0.3))
                                Text(deadline.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.6))
                                Text(days <= 0 ? "OVERDUE" : "\(days) days left")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(days <= 3 ? .red : days <= 7 ? Color(red: 1.0, green: 0.6, blue: 0.2) : .white.opacity(0.3))
                            }
                        }

                        Button {
                            showDatePicker.toggle()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: project.deadline == nil ? "calendar.badge.plus" : "calendar")
                                    .font(.system(size: 10))
                                Text(project.deadline == nil ? "SET DEADLINE" : "CHANGE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.white.opacity(0.35))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(ScaleButtonStyle())

                        if showDatePicker {
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { project.deadline ?? Date().addingTimeInterval(7 * 24 * 3600) },
                                    set: { newDate in
                                        project.deadline = newDate
                                        project.lastUpdatedAt = Date()
                                        NotificationService.scheduleDeadline(for: project)
                                    }
                                ),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                        }
                    }

                    SubtleDivider()

                    // MARK: - Tags
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "TAGS")

                        if !project.tags.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(project.tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag.uppercased())
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        Button {
                                            Haptic.light()
                                            project.tags.removeAll { $0 == tag }
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 7, weight: .bold))
                                        }
                                    }
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            TextField("add tag...", text: $newTag)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                                )

                            Button {
                                let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !tag.isEmpty else { return }
                                Haptic.light()
                                if !project.tags.contains(tag) {
                                    project.tags.append(tag)
                                }
                                newTag = ""
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(10)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }

                    SubtleDivider()

                    // MARK: - Notes
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "NOTES")
                        TextField("ideas, links, decisions, blockers...", text: $project.notes, axis: .vertical)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(8, reservesSpace: true)
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                            .onChange(of: project.notes) {
                                project.lastUpdatedAt = Date()
                            }
                    }

                    SubtleDivider()

                    // Info row
                    HStack {
                        InfoChip(label: "CREATED", value: project.createdAt.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        InfoChip(label: "STATUS", value: project.status.rawValue.uppercased())
                    }

                    SubtleDivider()

                    // MARK: - AI Kill Recommendation
                    if project.status != .shipped && project.status != .killed {
                        aiKillSection
                    }

                    // Kill / Shipped state
                    if project.status == .shipped {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(statusColor(.shipped))
                            Text("PROJECT SHIPPED")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(statusColor(.shipped))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(statusColor(.shipped).opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else if project.status == .killed {
                        VStack(spacing: 8) {
                            Text("// project killed")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.red.opacity(0.4))
                            if let reason = project.killReason, !reason.isEmpty {
                                Text("reason: \(reason)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.red.opacity(0.25))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    } else {
                        Button {
                            Haptic.warning()
                            showingKillSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 14))
                                Text("KILL THIS PROJECT")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.red.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red.opacity(0.15), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 60)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingKillSheet) {
            KillSheet(project: project, isPresented: $showingKillSheet)
        }
    }

    // MARK: - AI Kill Section

    var aiKillSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 11, weight: .bold))
                    Text("AI VERDICT")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .tracking(1)
                }
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))

                Spacer()

                if !isLoadingKillRec {
                    Button {
                        Haptic.medium()
                        fetchKillRec()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: killRec == nil ? "questionmark.circle" : "arrow.clockwise")
                                .font(.system(size: 10, weight: .bold))
                            Text(killRec == nil ? "SHOULD I KILL THIS?" : "RE-ANALYZE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            if isLoadingKillRec {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(Color(red: 0.4, green: 0.8, blue: 1.0))
                    Text("analyzing...")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.25))
                }
            } else if let rec = killRec {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(severityColor(rec.severity))
                            .frame(width: 8, height: 8)
                        Text(rec.verdict)
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(severityColor(rec.severity))
                    }

                    // Severity badge
                    Text(rec.severity.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(severityColor(rec.severity).opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(severityColor(rec.severity).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text(rec.reasoning)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(rec.signals, id: \.self) { signal in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(severityColor(rec.severity).opacity(0.4))
                                    .frame(width: 4, height: 4)
                                Text(signal)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                        }
                    }
                }
            } else if let err = killRecError {
                Text(err)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.red.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            HStack(spacing: 0) {
                Rectangle()
                    .fill(killRec.map { severityColor($0.severity) } ?? Color(red: 0.4, green: 0.8, blue: 1.0))
                    .frame(width: 2)
                Spacer()
            }
        )
        .background(
            Color(white: 0.04)
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 12,
                topTrailingRadius: 12
            )
        )
    }

    // MARK: - Helpers

    func daysAgo() -> String {
        let days = Calendar.current.dateComponents([.day], from: project.createdAt, to: Date()).day ?? 0
        if days == 0 { return "today" }
        if days == 1 { return "1 day ago" }
        return "\(days) days ago"
    }

    func fetchKillRec() {
        isLoadingKillRec = true
        killRecError = nil
        Task {
            do {
                killRec = try await aiService.killRecommendation(project: project)
            } catch {
                killRecError = error.localizedDescription
            }
            isLoadingKillRec = false
        }
    }

    func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "healthy":  return Color(red: 0.3, green: 0.9, blue: 0.4)
        case "drifting": return Color(red: 1.0, green: 0.8, blue: 0.2)
        case "stale":    return Color(red: 1.0, green: 0.5, blue: 0.2)
        case "dead":     return .red
        default:         return .white.opacity(0.4)
        }
    }
}

// MARK: - Info Chip
struct InfoChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.2))
                .tracking(1)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Flow Layout (for tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
