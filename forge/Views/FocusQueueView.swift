import SwiftUI
import SwiftData

// MARK: - Focus Item (unified wrapper)

enum FocusItemType {
    case project(Project)
    case skill(SkillTrack)

    var name: String {
        switch self {
        case .project(let p): return p.name
        case .skill(let s):   return s.name
        }
    }

    var id: UUID {
        switch self {
        case .project(let p): return p.id
        case .skill(let s):   return s.id
        }
    }

    var isProject: Bool {
        if case .project = self { return true }
        return false
    }

    var heuristicScore: Int {
        switch self {
        case .project(let p): return computeHeuristicScore(project: p)
        case .skill(let s):   return computeHeuristicScore(skill: s)
        }
    }
}

// MARK: - Focus Queue View

struct FocusQueueView: View {
    @Environment(\.modelContext) private var context
    @Environment(AIService.self) private var aiService
    @Query var allProjects: [Project]
    @Query var allSkills: [SkillTrack]

    @State private var showSettings = false
    @State private var showBrainDump = false
    @State private var showWeeklyReview = false
    @State private var appeared = false
    @State private var isAIOpinionExpanded = false

    var activeProjects: [Project] {
        allProjects.filter { $0.status != .killed && $0.status != .shipped }
    }

    var activeSkills: [SkillTrack] {
        allSkills.filter { $0.status != .acquired }
    }

    var focusItems: [FocusItemType] {
        var items: [FocusItemType] = []
        items += activeProjects.map { .project($0) }
        items += activeSkills.map { .skill($0) }

        if let analysis = aiService.lastAnalysis {
            return items.sorted { a, b in
                let rankA = analysis.rankings.first(where: { $0.name.lowercased() == a.name.lowercased() })?.rank ?? 999
                let rankB = analysis.rankings.first(where: { $0.name.lowercased() == b.name.lowercased() })?.rank ?? 999
                return rankA < rankB
            }
        } else {
            return items.sorted { $0.heuristicScore > $1.heuristicScore }
        }
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    actionBar
                    workloadBar

                    if focusItems.isEmpty {
                        emptyState
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionLabel(text: "FOCUS QUEUE")
                                .padding(.horizontal, 20)

                            VStack(spacing: 8) {
                                ForEach(Array(focusItems.enumerated()), id: \.element.id) { index, item in
                                    FocusCard(item: item, rank: index + 1, aiReason: aiReason(for: item))
                                        .opacity(appeared ? 1 : 0)
                                        .offset(y: appeared ? 0 : 16)
                                        .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.06),
                                            value: appeared
                                        )
                                }
                            }
                        }
                    }

                    aiOpinionCard
                        .padding(.top, 8)
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            appeared = true
            if aiService.lastAnalysis == nil && aiService.hasKey {
                Task { await aiService.analyze(projects: allProjects, skills: allSkills) }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .sheet(isPresented: $showBrainDump) {
            IdeaDumpView()
        }
        .sheet(isPresented: $showWeeklyReview) {
            WeeklyReviewSheet()
        }
    }

    // MARK: - Header

    var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("FOCUS QUEUE")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .tracking(2)
                Text("AI-RANKED")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0)) // primary-container
            }
            Spacer()
            Button {
                Haptic.light()
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    // MARK: - Action Bar (Brain Dump + Weekly Review)

    var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                Haptic.medium()
                showBrainDump = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.app")
                        .font(.system(size: 14))
                    Text("BRAIN DUMP")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.black)
                .overlay(
                    Rectangle()
                        .stroke(Color(white: 0.25), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())

            Button {
                Haptic.medium()
                showWeeklyReview = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                    Text("WEEKLY REVIEW")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(red: 0.4, green: 0.8, blue: 1.0))
                .overlay(
                    Rectangle()
                        .stroke(Color(red: 0.4, green: 0.8, blue: 1.0), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Workload Bar

    var workloadBar: some View {
        HStack(spacing: 16) {
            WorkloadChip(label: "PROJECTS", count: activeProjects.count, max: 3, color: .white)
            WorkloadChip(label: "SKILLS", count: activeSkills.filter { $0.status == .active }.count, max: 2, color: Color(red: 0.4, green: 0.8, blue: 1.0))
            Spacer()
            Text("\(focusItems.count) active")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - AI Opinion Card

    var aiOpinionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                Haptic.light()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isAIOpinionExpanded.toggle()
                }
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("AI STRATEGY INTEL")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(2)
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))

                    Spacer()

                    Image(systemName: isAIOpinionExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.6))
                }
            }
            .buttonStyle(.plain)

            if let analysis = aiService.lastAnalysis {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isAIOpinionExpanded.toggle()
                    }
                } label: {
                    Text(analysis.opinion)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.8))
                        .lineSpacing(6)
                        .lineLimit(isAIOpinionExpanded ? nil : 2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                if isAIOpinionExpanded {
                    HStack {
                        if let updated = aiService.lastUpdated {
                            Text("analyzed \(updated.formatted(.relative(presentation: .named)))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        
                        Spacer()
                        
                        if aiService.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(Color(red: 0.4, green: 0.8, blue: 1.0))
                        } else {
                            Button {
                                Haptic.medium()
                                Task { await aiService.analyze(projects: allProjects, skills: allSkills) }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("RE-ANALYZE")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.1))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.top, 4)
                }
            } else if let err = aiService.errorMessage {
                Text(err)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.red.opacity(0.8))
                    .lineLimit(isAIOpinionExpanded ? nil : 2)
            } else if !aiService.hasKey {
                Text("Add your Groq API key in Settings to get AI-powered priority analysis.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(isAIOpinionExpanded ? nil : 2)
            } else {
                HStack {
                    Text("Ready for analysis.")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Spacer()
                    
                    if aiService.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(Color(red: 0.4, green: 0.8, blue: 1.0))
                    } else {
                        Button {
                            Haptic.medium()
                            Task { await aiService.analyze(projects: allProjects, skills: allSkills) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 10, weight: .bold))
                                Text("ANALYZE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.1))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
        }
        .padding(20)
        .background(Color.black)
        .overlay(
            Rectangle()
                .stroke(Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Empty State

    var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundColor(.white.opacity(0.06))
            Text("// nothing to focus on")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(0.12))
            Text("add projects or skills to see\nyour priority queue")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.06))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    func aiReason(for item: FocusItemType) -> String? {
        aiService.lastAnalysis?.rankings.first(where: {
            $0.name.lowercased() == item.name.lowercased()
        })?.reason
    }
}

// MARK: - Focus Card

struct FocusCard: View {
    let item: FocusItemType
    let rank: Int
    let aiReason: String?

    var accent: Color {
        switch item {
        case .project(let p): return priorityColor(p.priority)
        case .skill:          return Color(red: 0.4, green: 0.8, blue: 1.0)
        }
    }

    var typeLabel: String {
        item.isProject ? "Project" : "Skill"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Rank Block
            VStack {
                Spacer()
                Text("\(rank)")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(rank == 1 ? accent : .white.opacity(0.3))
                Spacer()
            }
            .frame(width: 64)
            .background(Color(white: 0.04)) // bg-surface-container-lowest
            .overlay(
                Rectangle()
                    .stroke(Color(white: 0.13), lineWidth: 1)
                    .edgesIgnoringSafeArea(.all)
            )

            // Content Block
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(item.name)
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(rank == 1 ? accent : .white)
                    Spacer()
                    
                    // Top right label
                    HStack(spacing: 4) {
                        if rank == 1 {
                            Circle()
                                .fill(accent)
                                .frame(width: 6, height: 6)
                                .modifier(PulseEffect())
                        }
                        Text(rank == 1 ? "LIVE" : "QUEUED")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(rank == 1 ? accent : .white.opacity(0.4))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(rank == 1 ? accent.opacity(0.1) : Color(white: 0.13))
                    .border(rank == 1 ? accent.opacity(0.3) : Color(white: 0.25))
                }

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: item.isProject ? "folder" : "terminal")
                            .font(.system(size: 12))
                        Text(typeLabel)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.4))

                    switch item {
                    case .project(let p):
                        if let d = p.deadline {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                DeadlineLabel(date: d)
                            }
                        }
                    case .skill(let s):
                        HStack(spacing: 6) {
                            Image(systemName: "bolt")
                                .font(.system(size: 12))
                            Text("\(Int(s.progress * 100))% Mastery")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            .padding(16)
        }
        .frame(minHeight: 100)
        .background(
            ZStack {
                Color.black
                if rank == 1 {
                    LinearGradient(
                        colors: [accent.opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        )
        .overlay(
            Rectangle()
                .stroke(Color(white: 0.13), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Deadline Label

struct DeadlineLabel: View {
    let date: Date

    var days: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock")
                .font(.system(size: 8))
            Text(days <= 0 ? "OVERDUE" : "\(days)d")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
        }
        .foregroundColor(days <= 7 ? .red.opacity(0.7) : .white.opacity(0.25))
    }
}

// MARK: - Workload Chip

struct WorkloadChip: View {
    let label: String
    let count: Int
    let max: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(0..<max, id: \.self) { i in
                    Circle()
                        .fill(i < count ? color.opacity(0.8) : color.opacity(0.1))
                        .frame(width: 6, height: 6)
                }
            }
            Text("\(label) \(count)/\(max)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.25))
        }
    }
}

// MARK: - Skill Status Pill

struct SkillStatusPill: View {
    let status: SkillStatus

    var color: Color {
        switch status {
        case .queued:     return Color(red: 0.5, green: 0.5, blue: 0.6)
        case .active:     return Color(red: 0.2, green: 0.85, blue: 0.9)
        case .practicing: return Color(red: 0.75, green: 0.5, blue: 1.0)
        case .acquired:   return Color(red: 0.3, green: 0.9, blue: 0.4)
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            if status == .active {
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                    .modifier(PulseEffect())
            }
            Text(status.rawValue.uppercased())
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Skill Category Badge

struct SkillCategoryBadge: View {
    let category: SkillCategory

    var color: Color {
        skillCategoryColor(category)
    }

    var body: some View {
        Text(category.rawValue.uppercased())
            .font(.system(size: 8, weight: .heavy, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

// MARK: - Progress Arc

struct ProgressArc: View {
    let progress: Double
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 2)
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
