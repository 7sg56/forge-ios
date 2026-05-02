import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query var allProjects: [Project]

    var activeProjects: [Project] {
        allProjects.filter { $0.status != .killed }
    }

    @State private var showingBrainDump = false
    @State private var showingKillLog = false
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ACTIVE VECTORS")
                                    .font(Font.forgeH1)
                                    .foregroundColor(ForgeTheme.onSurface)
                                    .tracking(2)
                                Text("// Deploying high-leverage assets")
                                    .font(Font.forgeCodeSm)
                                    .foregroundColor(ForgeTheme.outline)
                            }
                            Spacer()
                            Button {
                                Haptic.light()
                                showingKillLog = true
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(ForgeTheme.highPriority) // error color
                                        .frame(width: 6, height: 6)
                                    Text("KILL LOG")
                                        .font(Font.forgeLabelCaps)
                                }
                                .foregroundColor(ForgeTheme.highPriority)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(ForgeTheme.pureBlack)
                                .overlay(
                                    Rectangle().stroke(ForgeTheme.highPriority.opacity(0.5), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }

                        // Active slot indicators
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { i in
                                Rectangle()
                                    .fill(i < activeProjects.count ? ForgeTheme.onSurface : ForgeTheme.border)
                                    .frame(width: 24, height: 4)
                            }
                            Text("ACTIVE \(activeProjects.count)/3")
                                .font(Font.forgeLabelCaps)
                                .foregroundColor(ForgeTheme.outline)
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 24)
                    .background(ForgeTheme.pureBlack)

                    // Project Cards
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            ForEach(Array(activeProjects
                                .sorted(by: { priorityOrder($0.priority) < priorityOrder($1.priority) })
                                .enumerated()), id: \.element.id) { index, project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(CardPressStyle())
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 16)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.06),
                                    value: appeared
                                )
                            }

                            // Empty slots — tappable, opens Brain Dump
                            ForEach(0..<max(0, 3 - activeProjects.count), id: \.self) { i in
                                Button {
                                    Haptic.medium()
                                    showingBrainDump = true
                                } label: {
                                    EmptySlotCard()
                                }
                                .buttonStyle(CardPressStyle())
                                .opacity(appeared ? 1 : 0)
                                .animation(
                                    .easeOut(duration: 0.5).delay(Double(activeProjects.count + i) * 0.06),
                                    value: appeared
                                )
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                    }
                }
            }
            .onAppear { appeared = true }
            .sheet(isPresented: $showingBrainDump) {
                IdeaDumpView()
            }
            .sheet(isPresented: $showingKillLog) {
                KillLogView()
            }
            .navigationBarHidden(true)
        }
    }

    func priorityOrder(_ p: Priority) -> Int {
        switch p {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

// MARK: - Project Card
struct ProjectCard: View {
    let project: Project

    var accent: Color { priorityColor(project.priority) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Content Area
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    HStack(spacing: 8) {
                        StatusPill(status: project.status)
                        PriorityBadge(priority: project.priority)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(project.name)
                        .font(Font.forgeH1)
                        .foregroundColor(ForgeTheme.onSurface)
                    
                    Text(project.tagline)
                        .font(Font.forgeBodyMono)
                        .foregroundColor(ForgeTheme.onSurfaceVariant)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                // Tags row
                if !project.tags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(project.tags.prefix(3), id: \.self) { tag in
                            Text(tag.uppercased())
                                .font(Font.forgeLabelCaps)
                                .foregroundColor(ForgeTheme.outline)
                        }
                        if project.tags.count > 3 {
                            Text("+\(project.tags.count - 3)")
                                .font(Font.forgeLabelCaps)
                                .foregroundColor(ForgeTheme.outline)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(20)

            Spacer()
            
            // Bottom Bar
            HStack {
                Text("v1.0.0") // Placeholder for version if we don't have one
                    .font(Font.forgeCodeSm)
                    .foregroundColor(ForgeTheme.outline)
                
                Spacer()
                
                if let deadline = project.deadline {
                    DeadlineLabel(date: deadline)
                } else {
                    Text(project.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(Font.forgeCodeSm)
                        .foregroundColor(ForgeTheme.outline)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(ForgeTheme.pureBlack)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(ForgeTheme.border),
                alignment: .top
            )
        }
        .frame(minHeight: 220)
        .background(
            ZStack {
                ForgeTheme.pureBlack
                LinearGradient(
                    colors: [accent.opacity(0.05), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            Rectangle()
                .stroke(ForgeTheme.border, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Empty Slot
struct EmptySlotCard: View {
    var body: some View {
        Rectangle()
            .fill(ForgeTheme.pureBlack)
            .frame(height: 120)
            .overlay(
                Rectangle()
                    .stroke(ForgeTheme.outlineVariant, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                        .foregroundColor(ForgeTheme.outline)
                    Text("INITIALIZE VECTOR")
                        .font(Font.forgeLabelCaps)
                        .foregroundColor(ForgeTheme.outline)
                        .tracking(1)
                }
            )
            .padding(.horizontal, 20)
    }
}
