import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query var allProjects: [Project]

    var activeProjects: [Project] {
        allProjects.filter { $0.status != .killed }
    }

    @State private var showingAdd = false
    @State private var showingKillLog = false
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("FORGE")
                                    .font(.system(size: 32, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("ship ideas, kill the rest")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.25))
                            }
                            Spacer()
                            Button {
                                Haptic.light()
                                showingKillLog = true
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.red.opacity(0.7))
                                        .frame(width: 6, height: 6)
                                    Text("KILL LOG")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.red.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.red.opacity(0.2), lineWidth: 0.5)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }

                        // Active slot indicators
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i < activeProjects.count ? Color.white.opacity(0.6) : Color.white.opacity(0.08))
                                    .frame(width: 24, height: 4)
                            }
                            Text("\(activeProjects.count)/3")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 28)

                    // Project Cards
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach(Array(activeProjects
                                .sorted(by: { priorityOrder($0.priority) < priorityOrder($1.priority) })
                                .enumerated()), id: \.element.id) { index, project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(CardPressStyle())
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1),
                                    value: appeared
                                )
                            }

                            // Empty slots
                            ForEach(0..<max(0, 3 - activeProjects.count), id: \.self) { i in
                                EmptySlotCard()
                                    .opacity(appeared ? 1 : 0)
                                    .animation(
                                        .easeOut(duration: 0.5).delay(Double(activeProjects.count + i) * 0.1),
                                        value: appeared
                                    )
                            }

                            // Add button
                            if activeProjects.count < 3 {
                                Button {
                                    Haptic.medium()
                                    showingAdd = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 12, weight: .bold))
                                        Text("NEW PROJECT")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundColor(.white.opacity(0.3))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [8, 6]))
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .onAppear { appeared = true }
            .sheet(isPresented: $showingAdd) {
                AddProjectSheet()
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
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 4)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(project.name.uppercased())
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    PriorityBadge(priority: project.priority)
                }

                Text(project.tagline)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    StatusPill(status: project.status)
                    Spacer()
                    Text(project.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.2))
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accent.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: accent.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
    }
}

// MARK: - Empty Slot
struct EmptySlotCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.015))
            .frame(height: 90)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.04), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            )
            .overlay(
                Text("// empty slot")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.08))
            )
            .padding(.horizontal, 20)
    }
}

// MARK: - Add Project Sheet
struct AddProjectSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var tagline = ""
    @State private var priority: Priority = .medium

    var body: some View {
        ZStack {
            AppBackground(tint: Color(red: 0.04, green: 0.04, blue: 0.1))

            VStack(alignment: .leading, spacing: 28) {
                // Header
                HStack {
                    Text("NEW PROJECT")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(10)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 36)

                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "NAME")
                    TextField("what are you building?", text: $name)
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

                // Tagline field
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "ONE LINE")
                    TextField("explain it in one breath", text: $tagline)
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

                // Priority picker
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "PRIORITY")
                    HStack(spacing: 10) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Button {
                                Haptic.light()
                                priority = p
                            } label: {
                                Text(p.rawValue.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(priority == p ? .black : .white.opacity(0.3))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(priority == p ? priorityColor(p) : Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .animation(.spring(response: 0.3), value: priority)
                        }
                    }
                }

                Spacer()

                // Create button
                Button {
                    guard !name.isEmpty else {
                        Haptic.warning()
                        return
                    }
                    Haptic.success()
                    let p = Project(name: name, tagline: tagline, priority: priority)
                    context.insert(p)
                    dismiss()
                } label: {
                    Text("FORGE IT")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
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
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
}
