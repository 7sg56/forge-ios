# Forge

**Ship ideas. Kill the rest. Level up.**

Forge is a personal developer OS for builders who track too many things and finish too few. It enforces a hard cap of **3 active projects** and **2 active skills** at a time, forcing you to prioritize ruthlessly. An AI-powered Focus Queue ranks everything together and tells you exactly what to work on next.

---

## Features

- **3-Slot Project Constraint** -- You can only have 3 active projects at any time. Want to start something new? Ship or kill something first.
- **Skill Tracker** -- Track certifications (AWS, Azure), languages (Rust, Go), frameworks, DevOps skills, and more with progress tracking and target dates.
- **2-Active-Skill Limit** -- Only 2 skills can be in "Active" learning status at once. Focus beats breadth.
- **AI-Powered Focus Queue** -- A unified priority view that ranks ALL your projects and skills together. Uses Gemini AI to give you an opinionated ranking with per-item reasoning.
- **AI Opinion** -- Get a brutally honest 2-3 sentence take on your current workload balance and strategy.
- **Visual Pipeline** -- Every project moves through `Ideating > Validating > Building > Shipped`. Skills move through `Queued > Active > Practicing > Acquired`.
- **Priority System** -- Tag projects as High, Medium, or Low priority with color-coded badges.
- **Kill Log** -- A dedicated graveyard for killed projects with documented reasons.
- **Progress Rings** -- Circular self-assessed progress indicators on every skill card.
- **Deadline Countdowns** -- Set target dates on projects and skill exams, see countdown timers.
- **Haptic Feedback** -- Tactile feedback on every interaction.
- **Dark-First UI** -- Monospaced typography, deep black backgrounds with subtle gradients, and accent-colored glow effects.
- **Persistent Storage** -- All data persists locally via SwiftData. No accounts, no cloud, no sync.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | SwiftUI |
| Persistence | SwiftData |
| AI | Google Gemini API |
| Min Deployment | iOS 17.0+ |
| Language | Swift 5.0 |
| Architecture | Single-target, model-view |

## Project Structure

```
forge/
├── forge.xcodeproj/
├── forge/
│   ├── forgeApp.swift
│   ├── Models/
│   │   ├── Project.swift
│   │   └── SkillTrack.swift
│   ├── Services/
│   │   └── AIService.swift
│   ├── Views/
│   │   ├── ContentView.swift         # Tab bar container
│   │   ├── FocusQueueView.swift      # AI priority manager
│   │   ├── HomeView.swift            # Project cards
│   │   ├── SkillsView.swift          # Skill tracker + add sheet
│   │   ├── SkillDetailView.swift     # Skill detail + pipeline
│   │   ├── ProjectDetailView.swift   # Project detail + pipeline
│   │   ├── KillLogView.swift         # Project graveyard
│   │   ├── KillSheet.swift           # Kill confirmation
│   │   ├── SettingsSheet.swift       # API key configuration
│   │   └── Components.swift          # Shared UI components
│   └── Assets.xcassets/
├── .gitignore
└── README.md
```

## Data Models

```swift
Project
├── id: UUID
├── name: String
├── tagline: String
├── status: ProjectStatus   // .ideating | .validating | .building | .shipped | .killed
├── priority: Priority      // .high | .medium | .low
├── createdAt: Date
├── killReason: String?
├── tags: [String]
├── notes: String
└── deadline: Date?

SkillTrack
├── id: UUID
├── name: String
├── category: SkillCategory  // .certification | .language | .framework | .devops | .softSkill | .design | .other
├── status: SkillStatus      // .queued | .active | .practicing | .acquired
├── notes: String
├── targetDate: Date?
├── progress: Double         // 0.0 to 1.0
└── createdAt: Date
```

## AI Integration

Forge uses the Gemini API (free tier) to analyze your workload:

1. Open the **Focus Queue** tab
2. Tap the gear icon and enter your Gemini API key (get one free at [Google AI Studio](https://aistudio.google.com))
3. Tap **ANALYZE** to get AI-powered priority rankings

The AI sees your project/skill names, statuses, deadlines, and progress. Nothing else leaves your device.

## Getting Started

### Prerequisites

- Xcode 16.0+
- iOS 17.0+ device or simulator
- (Optional) Gemini API key for AI features

### Build & Run

1. Clone the repo
2. Open `forge.xcodeproj` in Xcode
3. Select a simulator or device, hit `Cmd + R`

No dependencies. No package managers. No setup scripts. It just builds.

## Philosophy

Most productivity tools help you do more. Forge helps you do less -- but finish what you start. The 3-slot cap is intentional friction. The kill log is intentional accountability. The AI doesn't sugarcoat -- if you're spread too thin, it tells you.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
