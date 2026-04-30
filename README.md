# Forge

**Ship ideas. Kill the rest.**

Forge is a personal project OS for developers who build too many things and finish too few. It enforces a hard cap of **3 active projects** at a time, forcing you to prioritize ruthlessly. Every project flows through a visual pipeline -- from ideation to shipped or killed -- with a dedicated kill log that keeps you honest about what didn't make it and why.

---

## Features

- **3-Slot Constraint** -- You can only have 3 active projects at any time. Want to start something new? Ship or kill something first.
- **Visual Pipeline** -- Every project moves through `Ideating > Validating > Building > Shipped` with an interactive status pipeline you can tap through.
- **Priority System** -- Tag projects as High, Medium, or Low priority with color-coded badges (red, orange, blue).
- **Kill Log** -- A dedicated graveyard for killed projects. Each entry records the project name, date, and your honest reason for killing it.
- **Kill Sheet** -- A deliberate, friction-full confirmation flow when you kill a project. You write why it failed before it goes to the graveyard.
- **Haptic Feedback** -- Tactile feedback on every interaction -- light taps for navigation, medium for state changes, error buzz on kills.
- **Dark-First UI** -- Monospaced typography, deep black backgrounds with subtle gradients, and accent-colored glow effects. No light mode. No compromise.
- **Persistent Storage** -- All data persists locally via SwiftData. No accounts, no cloud, no sync.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | SwiftUI |
| Persistence | SwiftData |
| Min Deployment | iOS 17.0+ |
| Language | Swift 5.0 |
| Architecture | Single-target, model-view |

## Project Structure

```
forge/
├── forge.xcodeproj/          # Xcode project config
├── forge/                    # Source code
│   ├── forgeApp.swift        # App entry point
│   ├── Models/
│   │   └── Project.swift     # Project model (SwiftData @Model)
│   ├── Views/
│   │   ├── HomeView.swift        # Main screen, project cards, add flow
│   │   ├── ProjectDetailView.swift  # Detail view with pipeline + priority
│   │   ├── KillLogView.swift     # Graveyard of killed projects
│   │   ├── KillSheet.swift       # Kill confirmation sheet
│   │   └── Components.swift      # Shared UI (badges, pills, backgrounds, haptics)
│   └── Assets.xcassets/      # App icons and colors
├── .gitignore
└── README.md
```

## Data Model

```swift
Project
├── id: UUID
├── name: String
├── tagline: String
├── status: ProjectStatus   // .ideating | .validating | .building | .shipped | .killed
├── priority: Priority      // .high | .medium | .low
├── createdAt: Date
└── killReason: String?     // only set when killed
```

## Getting Started

### Prerequisites

- Xcode 16.0+
- iOS 17.0+ device or simulator

### Build & Run

1. Clone the repo:
   ```bash
   git clone https://github.com/YOUR_USERNAME/forge.git
   cd forge
   ```

2. Open in Xcode:
   ```bash
   open forge.xcodeproj
   ```

3. Select a simulator or device, hit `Cmd + R`.

No dependencies. No package managers. No setup scripts. It just builds.

## Philosophy

Most productivity tools help you do more. Forge helps you do less -- but finish what you start. The 3-slot cap is intentional friction. The kill log is intentional accountability. If you can't explain why you killed something, you probably shouldn't have started it.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
