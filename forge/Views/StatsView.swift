import SwiftUI
import SwiftData

struct StatsView: View {
    @Query var allProjects: [Project]
    @Query var allSkills: [SkillTrack]

    @State private var appeared = false

    // MARK: - Computed Stats

    var shipped: [Project] { allProjects.filter { $0.status == .shipped } }
    var killed: [Project]  { allProjects.filter { $0.status == .killed } }
    var active: [Project]  { allProjects.filter { $0.status != .killed && $0.status != .shipped } }

    var acquired: [SkillTrack]   { allSkills.filter { $0.status == .acquired } }
    var learning: [SkillTrack]   { allSkills.filter { $0.status == .active } }

    var totalItems: Int { allProjects.count + allSkills.count }

    var daysSinceStart: Int {
        let earliest = (allProjects.map(\.createdAt) + allSkills.map(\.createdAt)).min()
        guard let start = earliest else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
    }

    var killRate: Int {
        guard !allProjects.isEmpty else { return 0 }
        return Int((Double(killed.count) / Double(allProjects.count)) * 100)
    }

    var shipRate: Int {
        guard !allProjects.isEmpty else { return 0 }
        return Int((Double(shipped.count) / Double(allProjects.count)) * 100)
    }

    var avgProgress: Int {
        let skills = allSkills.filter { $0.status != .acquired }
        guard !skills.isEmpty else { return 0 }
        let total = skills.reduce(0.0) { $0 + $1.progress }
        return Int((total / Double(skills.count)) * 100)
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("STATS")
                            .font(Font.forgeH1)
                            .foregroundColor(ForgeTheme.onSurface)
                            .tracking(2)
                        Text(daysSinceStart > 0 ? "day \(daysSinceStart) of building" : "just getting started")
                            .font(Font.forgeCodeSm)
                            .foregroundColor(ForgeTheme.outline)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    // Primary metrics (Bento Grid)
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            StatBlock(
                                value: "\(shipped.count)",
                                label: "SHIPPED",
                                color: ForgeTheme.success,
                                icon: "checkmark.seal.fill",
                                index: 0,
                                appeared: appeared
                            )
                            StatBlock(
                                value: "\(killed.count)",
                                label: "KILLED",
                                color: ForgeTheme.highPriority,
                                icon: "xmark.circle.fill",
                                index: 1,
                                appeared: appeared
                            )
                        }
                        StatBlock(
                            value: "\(acquired.count)",
                            label: "ACQUIRED",
                            color: ForgeTheme.mediumPriority,
                            icon: "flame.fill",
                            index: 2,
                            appeared: appeared
                        )
                    }
                    .padding(.horizontal, 20)

                    SubtleDivider()
                        .padding(.horizontal, 20)

                    // Active workload
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel(text: "ACTIVE WORKLOAD")
                            .padding(.horizontal, 20)

                        VStack(spacing: 8) {
                            StatRow(label: "Active projects", value: "\(active.count)", max: "3", color: ForgeTheme.onSurface)
                            StatRow(label: "Skills learning", value: "\(learning.count)", max: "2", color: ForgeTheme.aiAccent)
                            StatRow(label: "Total tracked", value: "\(totalItems)", max: nil, color: ForgeTheme.onSurfaceVariant.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appeared)

                    SubtleDivider()
                        .padding(.horizontal, 20)

                    // Rates
                    VStack(alignment: .leading, spacing: 14) {
                        SectionLabel(text: "RATES")
                            .padding(.horizontal, 20)

                        HStack(spacing: 12) {
                            RateCard(label: "SHIP RATE", value: shipRate, color: ForgeTheme.success)
                            RateCard(label: "KILL RATE", value: killRate, color: ForgeTheme.highPriority)
                            RateCard(label: "AVG SKILL", value: avgProgress, color: ForgeTheme.mediumPriority)
                        }
                        .padding(.horizontal, 20)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: appeared)

                    SubtleDivider()
                        .padding(.horizontal, 20)

                    // Timeline
                    if !shipped.isEmpty || !killed.isEmpty || !acquired.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionLabel(text: "MILESTONES")
                                .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ForEach(Array(milestones.prefix(10).enumerated()), id: \.element.id) { index, m in
                                    MilestoneRow(milestone: m, isLast: index == milestones.prefix(10).count - 1)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: appeared)
                    }

                    // Empty overall
                    if totalItems == 0 {
                        VStack(spacing: 14) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.06))
                            Text("// nothing to measure yet")
                                .font(Font.forgeBodyMono)
                                .foregroundColor(ForgeTheme.outline)
                            Text("add projects or skills to see\nyour momentum stats")
                                .font(Font.forgeCodeSm)
                                .foregroundColor(ForgeTheme.outlineVariant)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear { appeared = true }
    }

    // MARK: - Milestones

    struct Milestone: Identifiable {
        let id = UUID()
        let name: String
        let type: String
        let date: Date
        let color: Color
        let icon: String
    }

    var milestones: [Milestone] {
        var list: [Milestone] = []
        for p in shipped {
            list.append(Milestone(name: p.name, type: "SHIPPED", date: p.lastUpdatedAt, color: ForgeTheme.success, icon: "checkmark.seal.fill"))
        }
        for p in killed {
            list.append(Milestone(name: p.name, type: "KILLED", date: p.lastUpdatedAt, color: ForgeTheme.highPriority, icon: "xmark.circle.fill"))
        }
        for s in acquired {
            list.append(Milestone(name: s.name, type: "ACQUIRED", date: s.createdAt, color: ForgeTheme.mediumPriority, icon: "flame.fill"))
        }
        return list.sorted { $0.date > $1.date }
    }
}

// MARK: - Stat Block (big number)

struct StatBlock: View {
    let value: String
    let label: String
    let color: Color
    let icon: String
    let index: Int
    let appeared: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.custom("SpaceGrotesk-Bold", size: 48))
                        .foregroundColor(ForgeTheme.onSurface)
                        .tracking(-2)

                    Text(label)
                        .font(Font.forgeCodeSm)
                        .foregroundColor(color)
                        .tracking(1)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color.opacity(0.8))
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(
            ZStack {
                ForgeTheme.pureBlack
                LinearGradient(
                    colors: [color.opacity(0.08), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            Rectangle()
                .stroke(ForgeTheme.border, lineWidth: 1) // border-[#222222]
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: appeared)
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    let max: String?
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(Font.forgeBodyMono)
                .foregroundColor(ForgeTheme.onSurfaceVariant)
            Spacer()
            if let max = max {
                HStack(spacing: 2) {
                    Text(value)
                        .font(Font.forgeBodyMono.weight(.bold))
                        .foregroundColor(color)
                    Text("/\(max)")
                        .font(Font.forgeBodyMono.weight(.bold))
                        .foregroundColor(ForgeTheme.outline)
                }
            } else {
                Text(value)
                    .font(Font.forgeBodyMono.weight(.bold))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(ForgeTheme.pureBlack)
        .overlay(
            Rectangle()
                .stroke(ForgeTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Rate Card

struct RateCard: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: CGFloat(value) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .square)) // technical square line cap
                    .rotationEffect(.degrees(-90))
                Text("\(value)%")
                    .font(Font.forgeBodyMono.weight(.bold))
                    .foregroundColor(ForgeTheme.onSurface)
            }
            .frame(width: 56, height: 56)

            Text(label)
                .font(Font.forgeLabelCaps)
                .foregroundColor(color)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(ForgeTheme.pureBlack)
        .overlay(
            Rectangle()
                .stroke(ForgeTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let milestone: StatsView.Milestone
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Pipeline graphics
            VStack(spacing: 0) {
                Circle()
                    .fill(milestone.color)
                    .frame(width: 10, height: 10)
                    .padding(.top, 4)
                
                if !isLast {
                    Rectangle()
                        .fill(ForgeTheme.border)
                        .frame(width: 2)
                        .padding(.vertical, 4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(milestone.name)
                        .font(Font.forgeH2) // Using H2 for the bold name, maybe bodyMono
                        .foregroundColor(ForgeTheme.onSurface)
                    
                    Text(milestone.type)
                        .font(Font.forgeLabelCaps)
                        .foregroundColor(milestone.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(
                            Rectangle()
                                .stroke(milestone.color.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Text(milestone.date.formatted(date: .abbreviated, time: .omitted))
                    .font(Font.forgeCodeSm)
                    .foregroundColor(ForgeTheme.outline)
            }
            .padding(.bottom, 24)

            Spacer()
        }
    }
}

