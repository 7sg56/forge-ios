import SwiftUI
import SwiftData

struct SkillCapSheet: View {
    @Query var allSkills: [SkillTrack]
    @Binding var isPresented: Bool

    @State private var appeared = false

    var activeSkills: [SkillTrack] {
        allSkills.filter { $0.status == .active }
    }

    let accent = Color(red: 1.0, green: 0.5, blue: 0.2)

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 28) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(accent)
                }

                VStack(spacing: 10) {
                    Text("SKILL CAP REACHED")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.white)

                    Text("You're already learning 2 things.\nPause one to activate this.")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                // Active skills list
                VStack(spacing: 10) {
                    SectionLabel(text: "CURRENTLY ACTIVE")

                    ForEach(activeSkills) { skill in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(skillCategoryColor(skill.category))
                                .frame(width: 3, height: 20)

                            Text(skill.name.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))

                            Spacer()

                            HStack(spacing: 4) {
                                ProgressArc(progress: skill.progress, size: 14, color: accent)
                                Text("\(Int(skill.progress * 100))%")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                        )
                    }
                }
                .padding(.horizontal, 10)

                Spacer()

                Button {
                    Haptic.light()
                    isPresented = false
                } label: {
                    Text("GOT IT")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 30)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)
        }
        .onAppear {
            Haptic.warning()
            appeared = true
        }
    }
}
