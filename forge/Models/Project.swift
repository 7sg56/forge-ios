import SwiftData
import Foundation

enum ProjectStatus: String, Codable, CaseIterable {
    case ideating   = "Ideating"
    case validating = "Validating"
    case building   = "Building"
    case shipped    = "Shipped"
    case killed     = "Killed"
}

enum Priority: String, Codable, CaseIterable {
    case high   = "High"
    case medium = "Medium"
    case low    = "Low"
}

@Model
class Project {
    var id: UUID
    var name: String
    var tagline: String
    var status: ProjectStatus
    var priority: Priority
    var createdAt: Date
    var killReason: String?

    init(name: String, tagline: String, priority: Priority) {
        self.id        = UUID()
        self.name      = name
        self.tagline   = tagline
        self.status    = .ideating
        self.priority  = priority
        self.createdAt = Date()
    }
}
