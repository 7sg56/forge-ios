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
            AppBackground(tint: Color(red: 0.04, green: 0.08, blue: 0.06))

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("STATS")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text(daysSinceStart > 0 ? "day \(daysSinceStart) of building" : "just getting started")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.2))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    // Primary metrics
                    HStack(spacing: 12) {
                        StatBlock(
                            value: "\(shipped.count)",
                            label: "SHIPPED",
                            color: Color(red: 0.3, green: 0.9, blue: 0.4),
                            icon: "checkmark.seal.fill",
                            index: 0,
                            appeared: appeared
                        )
                        StatBlock(
                            value: "\(killed.count)",
                            label: "KILLED",
                            color: .red,
                            icon: "xmark.circle.fill",
                            index: 1,
                            appeared: appeared
                        )
                        StatBlock(
                            value: "\(acquired.count)",
                            label: "ACQUIRED",
                            color: Color(red: 1.0, green: 0.5, blue: 0.2),
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
                            StatRow(label: "Active projects", value: "\(active.count)", max: "3", color: .white)
                            StatRow(label: "Skills learning", value: "\(learning.count)", max: "2", color: Color(red: 0.2, green: 0.85, blue: 0.9))
                            StatRow(label: "Total tracked", value: "\(totalItems)", max: nil, color: .white.opacity(0.5))
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
                            RateCard(label: "SHIP RATE", value: shipRate, color: Color(red: 0.3, green: 0.9, blue: 0.4))
                            RateCard(label: "KILL RATE", value: killRate, color: .red)
                            RateCard(label: "AVG SKILL", value: avgProgress, color: Color(red: 1.0, green: 0.5, blue: 0.2))
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

                            VStack(spacing: 6) {
                                ForEach(milestones.prefix(10), id: \.id) { m in
                                    MilestoneRow(milestone: m)
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
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.white.opacity(0.12))
                            Text("add projects or skills to see\nyour momentum stats")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.06))
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
            list.append(Milestone(name: p.name, type: "SHIPPED", date: p.lastUpdatedAt, color: Color(red: 0.3, green: 0.9, blue: 0.4), icon: "checkmark.seal.fill"))
        }
        for p in killed {
            list.append(Milestone(name: p.name, type: "KILLED", date: p.lastUpdatedAt, color: .red, icon: "xmark.circle.fill"))
        }
        for s in acquired {
            list.append(Milestone(name: s.name, type: "ACQUIRED", date: s.createdAt, color: Color(red: 1.0, green: 0.5, blue: 0.2), icon: "flame.fill"))
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 32, weight: .black, design: .monospaced))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(color.opacity(0.7))
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.12), lineWidth: 0.5)
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
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
            Spacer()
            if let max = max {
                Text("\(value)/\(max)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            } else {
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.025))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Rate Card

struct RateCard: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: CGFloat(value) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(value)%")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)

            Text(label)
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundColor(color.opacity(0.6))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.025))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let milestone: StatsView.Milestone

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: milestone.icon)
                .font(.system(size: 10))
                .foregroundColor(milestone.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(milestone.name.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    Text(milestone.type)
                        .font(.system(size: 7, weight: .heavy, design: .monospaced))
                        .foregroundColor(milestone.color.opacity(0.7))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(milestone.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                Text(milestone.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.white.opacity(0.15))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
