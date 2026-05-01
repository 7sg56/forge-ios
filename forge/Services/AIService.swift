import Foundation
import SwiftUI
import SwiftData

// MARK: - AI Response Types

struct AIRanking: Codable, Sendable {
    let name: String
    let type: String
    let rank: Int
    let reason: String
}

struct AIResponse: Codable, Sendable {
    let rankings: [AIRanking]
    let opinion: String
}

enum AIError: Error, LocalizedError, Sendable {
    case noAPIKey
    case apiError(Int)
    case parsingFailed
    case networkError(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .noAPIKey:          return "No API key configured. Add your Groq key in Settings."
        case .apiError(let c):   return "API returned status \(c)"
        case .parsingFailed:     return "Failed to parse AI response"
        case .networkError(let msg): return msg
        }
    }
}

// MARK: - AI Service (Groq)

@Observable
class AIService {
    static let shared = AIService()

    var lastAnalysis: AIResponse?
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?

    var apiKey: String? {
        UserDefaults.standard.string(forKey: "forge_groq_api_key")
    }

    var hasKey: Bool {
        guard let k = apiKey else { return false }
        return !k.isEmpty
    }

    func saveKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "forge_groq_api_key")
    }

    // MARK: - Analyze

    func analyze(projects: [Project], skills: [SkillTrack]) async {
        guard hasKey else {
            errorMessage = AIError.noAPIKey.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let prompt = buildPrompt(projects: projects, skills: skills)
            let raw = try await callGroq(prompt: prompt)
            let response = try parseResponse(raw)
            lastAnalysis = response
            lastUpdated = Date()
        } catch let e as AIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Prompt

    private func buildPrompt(projects: [Project], skills: [SkillTrack]) -> String {
        var lines: [String] = []
        lines.append("""
        You are Forge AI, a brutally honest developer productivity advisor.
        The user tracks projects and learning skills in an app called Forge.
        Analyze their current workload and tell them what to focus on.

        Rules:
        - Be opinionated and direct.
        - If they're spread too thin, say so.
        - If something should be killed or paused, say it.
        - Mix projects and skills into ONE ranked priority list.
        - Consider deadlines, status, progress, and strategic value.
        """)

        let active = projects.filter { $0.status != .killed && $0.status != .shipped }
        if active.isEmpty {
            lines.append("\nACTIVE PROJECTS: None")
        } else {
            lines.append("\nACTIVE PROJECTS:")
            for p in active {
                var detail = "- \(p.name): \"\(p.tagline)\" | Status: \(p.status.rawValue) | Priority: \(p.priority.rawValue)"
                if let d = p.deadline {
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
                    detail += " | Deadline: \(days) days away"
                }
                lines.append(detail)
            }
        }

        let tracked = skills.filter { $0.status != .acquired }
        if tracked.isEmpty {
            lines.append("\nSKILLS IN PROGRESS: None")
        } else {
            lines.append("\nSKILLS IN PROGRESS:")
            for s in tracked {
                var detail = "- \(s.name) [\(s.category.rawValue)]: Status: \(s.status.rawValue) | Progress: \(Int(s.progress * 100))%"
                if let d = s.targetDate {
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
                    detail += " | Target: \(days) days away"
                }
                lines.append(detail)
            }
        }

        lines.append("""

        Respond ONLY with valid JSON in this exact format, no markdown fences:
        {
          "rankings": [
            {"name": "exact item name", "type": "project" or "skill", "rank": 1, "reason": "one line reason"}
          ],
          "opinion": "2-3 sentence overall take on their workload and strategy"
        }
        """)

        return lines.joined(separator: "\n")
    }

    // MARK: - Groq API Call

    private func callGroq(prompt: String) async throws -> String {
        guard let key = apiKey else { throw AIError.noAPIKey }

        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            throw AIError.apiError(0)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [
                ["role": "system", "content": "You are Forge AI, a developer productivity advisor. Always respond with valid JSON only."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1024,
            "response_format": ["type": "json_object"]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw AIError.apiError(0) }
        guard http.statusCode == 200 else { throw AIError.apiError(http.statusCode) }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw AIError.parsingFailed
        }

        return text
    }

    // MARK: - Parse Response

    private func parseResponse(_ raw: String) throws -> AIResponse {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else { throw AIError.parsingFailed }

        do {
            return try JSONDecoder().decode(AIResponse.self, from: data)
        } catch {
            throw AIError.parsingFailed
        }
    }
}

// MARK: - Heuristic Scoring (offline fallback)

func computeHeuristicScore(project p: Project) -> Int {
    var score = 50

    switch p.priority {
    case .high:   score += 30
    case .medium: score += 15
    case .low:    score += 5
    }

    switch p.status {
    case .building:   score += 20
    case .validating: score += 15
    case .ideating:   score += 10
    case .shipped, .killed: score -= 100
    }

    if let d = p.deadline {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 999
        if days <= 3       { score += 40 }
        else if days <= 7  { score += 25 }
        else if days <= 14 { score += 15 }
        else if days <= 30 { score += 5 }
    }

    return min(100, max(0, score))
}

func computeHeuristicScore(skill s: SkillTrack) -> Int {
    var score = 40

    switch s.status {
    case .active:     score += 25
    case .practicing: score += 15
    case .queued:     score += 5
    case .acquired:   score -= 100
    }

    if let d = s.targetDate {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 999
        if days <= 7       { score += 35 }
        else if days <= 14 { score += 20 }
        else if days <= 30 { score += 10 }
    }

    score += Int(s.progress * 15)

    return min(100, max(0, score))
}
