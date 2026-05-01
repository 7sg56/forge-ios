import SwiftData
import Foundation
import SwiftUI

enum SkillCategory: String, Codable, CaseIterable, Sendable {
    case certification = "Certification"
    case language      = "Language"
    case framework     = "Framework"
    case devops        = "DevOps"
    case softSkill     = "Soft Skill"
    case design        = "Design"
    case other         = "Other"
}

enum SkillStatus: String, Codable, CaseIterable, Sendable {
    case queued     = "Queued"
    case active     = "Active"
    case practicing = "Practicing"
    case acquired   = "Acquired"
}

@Model
class SkillTrack {
    var id: UUID
    var name: String
    var category: SkillCategory
    var status: SkillStatus
    var notes: String
    var targetDate: Date?
    var progress: Double
    var createdAt: Date
    var linkedProjectName: String = ""

    init(name: String, category: SkillCategory, notes: String = "", targetDate: Date? = nil) {
        self.id        = UUID()
        self.name      = name
        self.category  = category
        self.status    = .queued
        self.notes     = notes
        self.targetDate = targetDate
        self.progress  = 0.0
        self.createdAt = Date()
    }
}
