import SwiftUI
import SwiftData

struct KillLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Query var allProjects: [Project]

    var killedProjects: [Project] {
        allProjects.filter { $0.status == .killed }
    }

    @State private var appeared = false

    var body: some View {
        ZStack {
            AppBackground(tint: Color(red: 0.08, green: 0.02, blue: 0.02))

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("KILL LOG")
                            .font(.system(size: 26, weight: .black, design: .monospaced))
                            .foregroundColor(.red)
                        Text("\(killedProjects.count) buried")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.red.opacity(0.3))
                    }
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
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 28)

                if killedProjects.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.06))
                        Text("// empty graveyard")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(0.12))
                        Text("nothing killed yet -- that's either\ndiscipline or denial")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.06))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(Array(killedProjects.enumerated()), id: \.element.id) { index, project in
                                KillCard(project: project)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 15)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08),
                                        value: appeared
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 50)
                    }
                }
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Kill Card
struct KillCard: View {
    let project: Project

    var body: some View {
        HStack(spacing: 0) {
            // Left red bar
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.red.opacity(0.4))
                .frame(width: 3)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(project.name.uppercased())
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .strikethrough(color: .red.opacity(0.3))
                    Spacer()
                    Text(project.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.12))
                }

                if let reason = project.killReason, !reason.isEmpty {
                    Text(">> \(reason)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.red.opacity(0.45))
                        .lineLimit(3)
                } else {
                    Text(">> no reason given")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.08))
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .padding(.vertical, 14)
        }
        .background(Color.red.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.08), lineWidth: 0.5)
        )
    }
}
