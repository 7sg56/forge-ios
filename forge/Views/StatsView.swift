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
                            .font(.system(size: 24, weight: .bold, design: .default)) // Space Grotesk equivalent
                            .foregroundColor(.white)
                            .tracking(2)
                        Text(daysSinceStart > 0 ? "day \(daysSinceStart) of building" : "just getting started")
                            .font(.system(size: 12, weight: .medium, design: .monospaced)) // JetBrains Mono
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    // Primary metrics (Bento Grid)
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            StatBlock(
                                value: "\(shipped.count)",
                                label: "SHIPPED",
                                color: Color(red: 0.13, green: 0.77, blue: 0.37), // #22C55E
                                icon: "checkmark.seal.fill",
                                index: 0,
                                appeared: appeared
                            )
                            StatBlock(
                                value: "\(killed.count)",
                                label: "KILLED",
                                color: Color(red: 0.94, green: 0.27, blue: 0.27), // #EF4444
                                icon: "xmark.circle.fill",
                                index: 1,
                                appeared: appeared
                            )
                        }
                        StatBlock(
                            value: "\(acquired.count)",
                            label: "ACQUIRED",
                            color: Color(red: 0.98, green: 0.45, blue: 0.09), // #F97316
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
                            StatRow(label: "Skills learning", value: "\(learning.count)", max: "2", color: Color(red: 0.22, green: 0.74, blue: 0.97)) // sky-400
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
                            RateCard(label: "SHIP RATE", value: shipRate, color: Color(red: 0.13, green: 0.77, blue: 0.37))
                            RateCard(label: "KILL RATE", value: killRate, color: Color(red: 0.94, green: 0.27, blue: 0.27))
                            RateCard(label: "AVG SKILL", value: avgProgress, color: Color(red: 0.98, green: 0.45, blue: 0.09))
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
            list.append(Milestone(name: p.name, type: "SHIPPED", date: p.lastUpdatedAt, color: Color(red: 0.13, green: 0.77, blue: 0.37), icon: "checkmark.seal.fill"))
        }
        for p in killed {
            list.append(Milestone(name: p.name, type: "KILLED", date: p.lastUpdatedAt, color: Color(red: 0.94, green: 0.27, blue: 0.27), icon: "xmark.circle.fill"))
        }
        for s in acquired {
            list.append(Milestone(name: s.name, type: "ACQUIRED", date: s.createdAt, color: Color(red: 0.98, green: 0.45, blue: 0.09), icon: "flame.fill"))
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
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .tracking(-2)

                    Text(label)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
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
                Color.black
                LinearGradient(
                    colors: [color.opacity(0.08), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            Rectangle()
                .stroke(Color(white: 0.13), lineWidth: 1) // border-[#222222]
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
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            if let max = max {
                HStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(color)
                    Text("/\(max)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
            } else {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color(white: 0.13), lineWidth: 1)
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
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 56, height: 56)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(color)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color(white: 0.13), lineWidth: 1)
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
                        .fill(Color(white: 0.13))
                        .frame(width: 2)
                        .padding(.vertical, 4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(milestone.name)
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    
                    Text(milestone.type)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(milestone.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(
                            Rectangle()
                                .stroke(milestone.color.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Text(milestone.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.bottom, 24)

            Spacer()
        }
    }
}

