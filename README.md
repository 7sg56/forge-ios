# Forge
> Ship ideas. Kill the rest. Level up.

3-project cap. 2-skill cap. AI Focus Queue. No exceptions.

Stack: SwiftUI . SwiftData . Groq (Llama 3.3 70B) . iOS 17+

---

## What is Forge?

Forge is a personal developer OS for builders who track too many things and finish too few. It enforces a hard cap of **3 active projects** and **2 active skills** at a time, forcing you to prioritize ruthlessly. An AI-powered Focus Queue ranks everything together and tells you exactly what to work on next.

## Core Features

- **3-Slot Project Constraint** -- You can only have 3 active projects at any time. Want to start something new? Ship or kill something first.
- **2-Active-Skill Limit** -- Only 2 skills can be in "Active" learning status at once. Focus beats breadth.
- **Brain Dump** -- Dump all your ideas at once. AI sorts them into Projects, Skills, and Ignore. Each project gets a verdict: WORTH BUILDING / NEEDS THOUGHT / KILL IT.
- **AI Focus Queue** -- A unified priority view that ranks ALL your projects and skills together using Groq (Llama 3.3 70B).
- **AI Kill Signal** -- Per-project AI analysis that tells you whether to kill, keep, or put a project on ice.
- **Weekly AI Review** -- Coaching-style weekly summary of what moved, what stalled, and what to kill.
- **Visual Pipeline** -- Projects: `Ideating > Validating > Building > Shipped`. Skills: `Queued > Active > Practicing > Acquired`.
- **Kill Log** -- A dedicated graveyard for killed projects with documented reasons.
- **Skill Tracker** -- Track certifications, languages, frameworks, DevOps skills, and more with progress tracking and target dates.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | SwiftUI |
| Persistence | SwiftData |
| AI | Groq API (Llama 3.3 70B Versatile) |
| Min Deployment | iOS 17.0+ |
| Language | Swift 5.0 |
| Architecture | Single-target, model-view |

## Project Structure

```
forge/
+-- forge.xcodeproj/
+-- forge/
|   +-- forgeApp.swift
|   +-- Models/
|   |   +-- Project.swift
|   |   +-- SkillTrack.swift
|   +-- Services/
|   |   +-- AIService.swift
|   |   +-- NotificationService.swift
|   +-- Views/
|   |   +-- ContentView.swift
|   |   +-- FocusQueueView.swift
|   |   +-- HomeView.swift
|   |   +-- SkillsView.swift
|   |   +-- SkillDetailView.swift
|   |   +-- ProjectDetailView.swift
|   |   +-- IdeaDumpView.swift
|   |   +-- KillLogView.swift
|   |   +-- KillSheet.swift
|   |   +-- SkillCapSheet.swift
|   |   +-- SettingsSheet.swift
|   |   +-- WeeklyReviewSheet.swift
|   |   +-- StatsView.swift
|   |   +-- Components.swift
|   +-- Assets.xcassets/
+-- .gitignore
+-- README.md
+-- LICENSE
```

## Getting Started

### Prerequisites

- Xcode 16.0+
- iOS 17.0+ device or simulator
- (Optional) Groq API key for AI features

### Build & Run

1. Clone the repo
2. Open `forge.xcodeproj` in Xcode
3. Select a simulator or device, hit `Cmd + R`

No dependencies. No package managers. No setup scripts. It just builds.

### AI Setup

1. Get a free Groq API key at [console.groq.com](https://console.groq.com)
2. Open Forge > Focus Queue > Settings gear
3. Paste your key

The AI sees project/skill names, statuses, deadlines, and progress. Nothing else leaves your device.

## Philosophy

Most productivity tools help you do more. Forge helps you do less -- but finish what you start. The 3-slot cap is intentional friction. The kill log is intentional accountability. The AI doesn't sugarcoat -- if you're spread too thin, it tells you.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
