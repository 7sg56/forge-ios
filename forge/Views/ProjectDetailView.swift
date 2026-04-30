import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var project: Project

    @State private var showingKillSheet = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // Name + priority header
                    VStack(alignment: .leading, spacing: 10) {
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
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel(text: "PIPELINE")
                        StatusPipeline(currentStatus: project.status) { newStatus in
                            Haptic.medium()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                project.status = newStatus
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
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel(text: "PRIORITY")
                        HStack(spacing: 10) {
                            ForEach(Priority.allCases, id: \.self) { p in
                                Button {
                                    Haptic.light()
                                    withAnimation(.spring(response: 0.3)) {
                                        project.priority = p
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

                    // Info row
                    HStack {
                        InfoChip(label: "CREATED", value: project.createdAt.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        InfoChip(label: "STATUS", value: project.status.rawValue.uppercased())
                    }

                    SubtleDivider()

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

    func daysAgo() -> String {
        let days = Calendar.current.dateComponents([.day], from: project.createdAt, to: Date()).day ?? 0
        if days == 0 { return "today" }
        if days == 1 { return "1 day ago" }
        return "\(days) days ago"
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
