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
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 32))
                .foregroundColor(accent.opacity(0.3))
            Text("Tap to generate your weekly review")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
            Button {
                runReview()
            } label: {
                Text("RUN REVIEW")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
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
        VStack(alignment: .leading, spacing: 22) {
            // Summary
            Text(r.summary)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(0.65))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .background(accent.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(accent.opacity(0.12), lineWidth: 0.5)
                )

            if !r.moved.isEmpty {
                reviewSection("MOVED FORWARD", items: r.moved, color: Color(red: 0.3, green: 0.9, blue: 0.4), icon: "arrow.up.right")
            }

            if !r.stalled.isEmpty {
                reviewSection("STALLED", items: r.stalled, color: Color(red: 1.0, green: 0.6, blue: 0.2), icon: "pause.fill")
            }

            if !r.shouldKill.isEmpty {
                reviewSection("CONSIDER KILLING", items: r.shouldKill, color: .red, icon: "xmark.circle")
            }

            if !r.shouldStart.isEmpty {
                reviewSection("SHOULD START", items: r.shouldStart, color: accent, icon: "plus.circle")
            }

            SubtleDivider()

            // Coach note
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 12))
                    .foregroundColor(accent.opacity(0.4))
                Text(r.coachNote)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .lineSpacing(3)
                    .italic()
            }
            .padding(14)
            .background(Color.white.opacity(0.025))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Refresh button
            Button {
                Haptic.medium()
                runReview()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .bold))
                    Text("REFRESH")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundColor(accent.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(accent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    func reviewSection(_ title: String, items: [String], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                SectionLabel(text: title)
            }
            .foregroundColor(color)

            ForEach(items, id: \.self) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(color.opacity(0.6))
                        .frame(width: 4, height: 4)
                    Text(item)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
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
