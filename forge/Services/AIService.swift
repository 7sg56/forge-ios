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

struct IdeaValidation: Codable, Sendable {
    let verdict: String
    let roast: String
    let questions: [String]
    let suggestion: String?
}

struct KillRecommendation: Codable, Sendable {
    let shouldKill: Bool
    let verdict: String
    let severity: String
    let reasoning: String
    let signals: [String]
}

struct WeeklyReviewResponse: Codable, Sendable {
    let summary: String
    let moved: [String]
    let stalled: [String]
    let shouldKill: [String]
    let shouldStart: [String]
    let coachNote: String
}

struct BrainDumpResult: Codable, Sendable, Equatable {
    let projects: [BrainDumpItem]
    let skills: [BrainDumpItem]
    let ignore: [BrainDumpItem]
}

struct BrainDumpItem: Codable, Sendable, Equatable {
    let name: String
    let reason: String
    let suggestedPriority: String?
    let verdict: String?
    let pro: String?
    let con: String?
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

    // MARK: - API Key
    // Hardcoded for convenience. Override in Settings if needed.
    private let hardcodedKey = "PASTE_YOUR_GROQ_KEY_HERE"

    var apiKey: String? {
        let saved = UserDefaults.standard.string(forKey: "forge_groq_api_key")
        if let saved, !saved.isEmpty { return saved }
        return hardcodedKey.isEmpty || hardcodedKey == "PASTE_YOUR_GROQ_KEY_HERE" ? nil : hardcodedKey
    }

    var hasKey: Bool {
        guard let k = apiKey else { return false }
        return !k.isEmpty
    }

    func saveKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "forge_groq_api_key")
    }

    // MARK: - Focus Queue Analysis

    func analyze(projects: [Project], skills: [SkillTrack]) async {
        guard hasKey else {
            errorMessage = AIError.noAPIKey.localizedDescription
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let prompt = buildAnalysisPrompt(projects: projects, skills: skills)
            let raw = try await callGroq(prompt: prompt)
            let response = try parseJSON(raw, as: AIResponse.self)
            lastAnalysis = response
            lastUpdated = Date()
        } catch let e as AIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Idea Validator

    func validateIdea(name: String, tagline: String) async throws -> IdeaValidation {
        guard hasKey else { throw AIError.noAPIKey }

        let prompt = """
        You are Forge AI, a brutally honest startup/project idea validator.
        A developer wants to build a new side project. Roast the idea, poke holes in it, ask "who is this for?" Return a verdict.

        PROJECT NAME: \(name)
        ONE-LINER: \(tagline.isEmpty ? "no description given" : tagline)

        Be harsh but fair. Consider:
        - Is this solving a real problem or just "cool tech"?
        - Who is the target user? Is it clear?
        - Is this realistic for a side project?
        - Has this been done to death?
        - Is there a unique angle?

        Respond ONLY with valid JSON:
        {
          "verdict": "WORTH BUILDING" or "NEEDS MORE THOUGHT" or "KILL IT",
          "roast": "2-3 sentence brutal honest take",
          "questions": ["hard question 1", "hard question 2", "hard question 3"],
          "suggestion": "one-line suggestion to improve the idea, or null"
        }
        """

        let raw = try await callGroq(prompt: prompt)
        return try parseJSON(raw, as: IdeaValidation.self)
    }

    // MARK: - Kill Recommendation

    func killRecommendation(project: Project) async throws -> KillRecommendation {
        guard hasKey else { throw AIError.noAPIKey }

        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: project.lastUpdatedAt, to: Date()).day ?? 0
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: project.createdAt, to: Date()).day ?? 0

        var deadlineInfo = "No deadline set"
        if let d = project.deadline {
            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
            deadlineInfo = daysLeft <= 0 ? "OVERDUE by \(abs(daysLeft)) days" : "\(daysLeft) days until deadline"
        }

        let prompt = """
        You are Forge AI. A developer is asking whether they should kill a project. Be honest but fair.
        DO NOT jump straight to "kill it". Projects need time. Use a graduated response:

        SEVERITY GUIDE (use this):
        - If last activity was < 7 days ago: almost always say KEEP GOING. A few days of inactivity is normal.
        - If last activity was 7-14 days ago: suggest they revisit it soon, maybe re-prioritize, but don't panic.
        - If last activity was 14-30 days ago: suggest PUT ON ICE -- it's drifting but not dead.
        - If last activity was 30+ days ago: NOW you can consider KILL IT, but only if there are other red flags too.
        - If the project is actively being built or has recent progress, lean toward KEEP GOING regardless.
        - If there's a deadline approaching, factor that in -- urgency can revive a stalled project.

        PROJECT: \(project.name)
        DESCRIPTION: \(project.tagline)
        STATUS: \(project.status.rawValue)
        PRIORITY: \(project.priority.rawValue)
        CREATED: \(daysSinceCreation) days ago
        LAST ACTIVITY: \(daysSinceUpdate) days ago
        DEADLINE: \(deadlineInfo)
        TAGS: \(project.tags.joined(separator: ", ").isEmpty ? "none" : project.tags.joined(separator: ", "))
        NOTES: \(project.notes.isEmpty ? "none" : String(project.notes.prefix(200)))

        Consider:
        - How long has it ACTUALLY been inactive? A few days is fine.
        - Is the developer just busy or has this been genuinely abandoned?
        - Does it have momentum signals (recent notes, tags, status changes)?
        - Is it worth giving more time before making a drastic decision?
        - Would their time be better spent elsewhere, or should they just push through?

        Respond ONLY with valid JSON:
        {
          "shouldKill": true or false,
          "verdict": "KILL IT" or "KEEP GOING" or "PUT ON ICE" or "GIVE IT TIME",
          "severity": "healthy" or "drifting" or "stale" or "dead",
          "reasoning": "2-3 sentence direct explanation",
          "signals": ["signal 1", "signal 2", "signal 3"]
        }
        """

        let raw = try await callGroq(prompt: prompt)
        return try parseJSON(raw, as: KillRecommendation.self)
    }

    // MARK: - Weekly Review

    func weeklyReview(projects: [Project], skills: [SkillTrack]) async throws -> WeeklyReviewResponse {
        guard hasKey else { throw AIError.noAPIKey }

        var lines: [String] = []
        lines.append("""
        You are Forge AI acting as a weekly coach. Review this developer's entire workload.
        Give a direct "state of the union" -- what moved, what stalled, what needs attention.
        Be opinionated but fair. This should feel like a coach, not a hitman.
        
        IMPORTANT: Don't be trigger-happy with kill recommendations.
        - If something has been inactive for just a few days, suggest re-engaging with it, not killing it.
        - Only recommend killing projects that have been truly abandoned (30+ days inactive with no signs of life).
        - For projects that are drifting (1-3 weeks inactive), suggest putting them on ice or re-prioritizing.
        - Distinguish between "stalled and needs a push" vs "dead and should be buried".
        """)

        lines.append("\nPROJECTS:")
        for p in projects where p.status != .killed {
            let daysAgo = Calendar.current.dateComponents([.day], from: p.lastUpdatedAt, to: Date()).day ?? 0
            var detail = "- \(p.name): \"\(p.tagline)\" | \(p.status.rawValue) | \(p.priority.rawValue) | last touched \(daysAgo)d ago"
            if let d = p.deadline {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
                detail += " | deadline: \(days)d"
            }
            lines.append(detail)
        }

        lines.append("\nSKILLS:")
        for s in skills where s.status != .acquired {
            var detail = "- \(s.name) [\(s.category.rawValue)]: \(s.status.rawValue) | \(Int(s.progress * 100))%"
            if let d = s.targetDate {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: d).day ?? 0
                detail += " | target: \(days)d"
            }
            if !s.linkedProjectName.isEmpty {
                detail += " | linked to: \(s.linkedProjectName)"
            }
            lines.append(detail)
        }

        let killed = projects.filter { $0.status == .killed }
        if !killed.isEmpty {
            lines.append("\nRECENTLY KILLED: \(killed.map { $0.name }.joined(separator: ", "))")
        }

        lines.append("""

        Respond ONLY with valid JSON:
        {
          "summary": "2-3 sentence overall weekly take",
          "moved": ["things that made progress"],
          "stalled": ["things that stalled -- distinguish between 'needs a push' vs 'truly dead'"],
          "shouldKill": ["ONLY things that are truly abandoned (30+ days inactive, no momentum). If nothing qualifies, return empty array. Do NOT recommend killing things that just need more time."],
          "shouldStart": ["things they should consider starting or accelerating"],
          "coachNote": "1-2 sentence motivational/strategic closing note"
        }
        """)

        let raw = try await callGroq(prompt: lines.joined(separator: "\n"))
        return try parseJSON(raw, as: WeeklyReviewResponse.self)
    }

    // MARK: - Brain Dump Sorter

    func batchSortIdeas(rawText: String) async throws -> BrainDumpResult {
        guard hasKey else { throw AIError.noAPIKey }

        let prompt = """
        You are Forge AI. A developer just did a brain dump of every idea, certification, skill,
        and random thought they have. Your job: sort them into actionable categories.

        BRAIN DUMP:
        \(rawText)

        Rules:
        - "projects" = things they could build (apps, tools, side projects)
        - "skills" = things they should learn (languages, certs, frameworks, soft skills)
        - "ignore" = things that are noise, too vague, or not worth pursuing right now
        - Be ruthless about the ignore pile. Most ideas are noise.
        - For each item, give a one-line reason why it belongs there.
        - suggestedPriority is "high", "medium", or "low" (null for ignored items)
        - For PROJECTS ONLY: also include a "verdict" field ("WORTH BUILDING", "NEEDS THOUGHT", or "KILL IT"), a "pro" (one-line strongest argument for building it), and a "con" (one-line biggest risk or weakness). Be brutally honest.
        - For skills and ignored items, set verdict, pro, and con to null.

        Respond ONLY with valid JSON:
        {
          "projects": [{"name": "...", "reason": "...", "suggestedPriority": "high/medium/low", "verdict": "WORTH BUILDING/NEEDS THOUGHT/KILL IT", "pro": "...", "con": "..."}],
          "skills": [{"name": "...", "reason": "...", "suggestedPriority": "high/medium/low", "verdict": null, "pro": null, "con": null}],
          "ignore": [{"name": "...", "reason": "...", "suggestedPriority": null, "verdict": null, "pro": null, "con": null}]
        }
        """

        let raw = try await callGroq(prompt: prompt)
        return try parseJSON(raw, as: BrainDumpResult.self)
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

    private func parseJSON<T: Decodable>(_ raw: String, as type: T.Type) throws -> T {
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
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AIError.parsingFailed
        }
    }

    // MARK: - Analysis Prompt Builder

    private func buildAnalysisPrompt(projects: [Project], skills: [SkillTrack]) -> String {
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
