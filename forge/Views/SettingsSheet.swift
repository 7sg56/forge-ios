import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var testStatus: TestStatus = .idle
    @State private var appeared = false

    enum TestStatus: Sendable {
        case idle, testing, success, failed(String)
    }

    var body: some View {
        ZStack {
            AppBackground(tint: Color(red: 0.04, green: 0.04, blue: 0.1))

            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("SETTINGS")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
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
                .padding(.top, 36)

                SubtleDivider()

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 12))
                        Text("GROQ API KEY")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .tracking(1)
                    }
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))

                    Text("Required for AI-powered priority analysis. Get a free key from console.groq.com.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.25))
                        .lineSpacing(3)

                    SecureField("paste your API key here", text: $apiKey)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )

                    HStack(spacing: 12) {
                        Button {
                            Haptic.medium()
                            AIService.shared.saveKey(apiKey)
                            Haptic.success()
                        } label: {
                            Text("SAVE KEY")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.4, green: 0.8, blue: 1.0))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Button {
                            Haptic.light()
                            testKey()
                        } label: {
                            HStack(spacing: 6) {
                                if case .testing = testStatus {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 10))
                                }
                                Text("TEST")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    switch testStatus {
                    case .success:
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connection successful")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.green.opacity(0.7))
                        }
                    case .failed(let msg):
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text(msg)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.red.opacity(0.7))
                                .lineLimit(2)
                        }
                    default:
                        EmptyView()
                    }
                }

                SubtleDivider()

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "ABOUT FORGE AI")
                    Text("Forge uses Groq (Llama 3.3 70B) to analyze your active projects and skills, then gives you an opinionated priority ranking. The AI sees your project names, statuses, deadlines, and skill progress -- nothing else leaves your device.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.2))
                        .lineSpacing(3)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: appeared)
        }
        .onAppear {
            appeared = true
            apiKey = AIService.shared.apiKey ?? ""
        }
    }

    func testKey() {
        guard !apiKey.isEmpty else {
            testStatus = .failed("Enter a key first")
            return
        }
        testStatus = .testing
        AIService.shared.saveKey(apiKey)

        Task {
            guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
                testStatus = .failed("Invalid URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 15

            let body: [String: Any] = [
                "model": "llama-3.3-70b-versatile",
                "messages": [["role": "user", "content": "Reply with just OK"]],
                "max_tokens": 5
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    Haptic.success()
                    testStatus = .success
                } else {
                    Haptic.error()
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    testStatus = .failed("API returned status \(code)")
                }
            } catch {
                Haptic.error()
                testStatus = .failed(error.localizedDescription)
            }
        }
    }
}
