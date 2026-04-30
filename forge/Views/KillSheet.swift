import SwiftUI
import SwiftData

struct KillSheet: View {
    @Bindable var project: Project
    @Binding var isPresented: Bool

    @State private var reason = ""
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Dark red-tinted background
            ZStack {
                Color.black
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.02, blue: 0.02),
                        Color(red: 0.05, green: 0.01, blue: 0.01),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("KILL PROJECT")
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundColor(.red)
                        Text("this is permanent")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.red.opacity(0.35))
                    }
                    Spacer()
                    Button {
                        isPresented = false
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

                // Project name
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.red.opacity(0.4))
                        .frame(width: 3, height: 18)
                    Text(project.name.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .strikethrough(color: .red.opacity(0.4))
                }

                // Reason field
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "REASON FOR KILLING")
                    TextField("be honest -- why didn't this work?", text: $reason, axis: .vertical)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(4, reservesSpace: true)
                        .padding(14)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.12), lineWidth: 0.5)
                        )
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        Haptic.error()
                        project.status = .killed
                        project.killReason = reason.isEmpty ? nil : reason
                        isPresented = false
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text("CONFIRM KILL")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.7), Color.red.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .red.opacity(0.2), radius: 8, y: 4)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        isPresented = false
                    } label: {
                        Text("CANCEL")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.25))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)
        }
        .onAppear {
            Haptic.warning()
            appeared = true
        }
    }
}
