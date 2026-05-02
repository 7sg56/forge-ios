import SwiftUI
import SwiftData

struct WeeklyReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AIService.self) private var aiService
    @Query var allProjects: [Project]
    @Query var allSkills: [SkillTrack]

    @State private var review: WeeklyReviewResponse?
    @State private var isLoading = false
    @State private var errorMsg: String?
    @State private var appeared = false

    let accent = Color(red: 0.4, green: 0.8, blue: 1.0)

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if isLoading {
                            loadingState
                        } else if let review = review {
                            reviewContent(review)
                        } else if let err = errorMsg {
                            errorState(err)
                        } else {
                            promptState
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 80)
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: appeared)
        }
        .onAppear {
            appeared = true
            if review == nil && !isLoading {
                runReview()
            }
        }
    }

    // MARK: - Header

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("WEEKLY REVIEW")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text("ai coach report")
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

    // MARK: - States

    var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(accent)
            Text("analyzing your week...")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    var promptState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 32))
                .foregroundColor(accent.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("WEEKLY DIAGNOSTIC")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(accent)
                Text("Compile progress, identify bottlenecks, and re-calibrate focus.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button {
                Haptic.medium()
                runReview()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .font(.system(size: 14))
                    Text("EXECUTE REVIEW")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(accent)
                .overlay(
                    Rectangle()
                        .stroke(accent, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    func errorState(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Text(msg)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.red.opacity(0.6))
            Button {
                runReview()
            } label: {
                Text("RETRY")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Review Content

    func reviewContent(_ r: WeeklyReviewResponse) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Summary - System Diagnostic
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundColor(accent)
                    Text("SYSTEM DIAGNOSTIC")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accent.opacity(0.1))
                .overlay(
                    Rectangle().stroke(accent.opacity(0.3), lineWidth: 1)
                )

                Text(r.summary)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .background(Color.black)
                    .overlay(
                        Rectangle().stroke(accent.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.top, -1)
            }

            VStack(spacing: 16) {
                if !r.moved.isEmpty {
                    reviewSection("PROGRESS DETECTED", items: r.moved, color: Color(red: 0.3, green: 0.9, blue: 0.4), icon: "arrow.up.right")
                }

                if !r.stalled.isEmpty {
                    reviewSection("BOTTLENECKS", items: r.stalled, color: Color(red: 1.0, green: 0.6, blue: 0.2), icon: "exclamationmark.triangle")
                }

                if !r.shouldKill.isEmpty {
                    reviewSection("NEEDS DECISION", items: r.shouldKill, color: Color(red: 1.0, green: 0.5, blue: 0.2), icon: "exclamationmark.octagon")
                }

                if !r.shouldStart.isEmpty {
                    reviewSection("QUEUED FOR DEPLOYMENT", items: r.shouldStart, color: accent, icon: "plus.app")
                }
            }

            SubtleDivider()

            // Coach note
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .foregroundColor(accent.opacity(0.8))
                    Text("AI DIRECTIVE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(accent.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.1))
                .overlay(
                    Rectangle().stroke(Color(white: 0.2), lineWidth: 1)
                )

                Text(r.coachNote)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(4)
                    .padding(16)
                    .background(Color.black)
                    .overlay(
                        Rectangle().stroke(Color(white: 0.2), lineWidth: 1)
                    )
                    .padding(.top, -1)
            }

            // Refresh button
            Button {
                Haptic.medium()
                runReview()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .bold))
                    Text("RECALCULATE DIAGNOSTIC")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundColor(accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accent.opacity(0.1))
                .overlay(
                    Rectangle()
                        .stroke(accent.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    func reviewSection(_ title: String, items: [String], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1)
            }
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.1))
            .overlay(
                Rectangle().stroke(color.opacity(0.3), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 12) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Text("»")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(color.opacity(0.6))
                        Text(item)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black)
            .overlay(
                Rectangle().stroke(color.opacity(0.3), lineWidth: 1)
            )
            .padding(.top, -1)
        }
    }

    // MARK: - Actions

    func runReview() {
        isLoading = true
        errorMsg = nil
        Task {
            do {
                review = try await aiService.weeklyReview(projects: allProjects, skills: allSkills)
            } catch {
                errorMsg = error.localizedDescription
            }
            isLoading = false
        }
    }
}
