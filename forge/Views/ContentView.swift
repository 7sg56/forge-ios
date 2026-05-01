import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var aiService = AIService.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:  FocusQueueView()
                case 1:  HomeView()
                case 2:  SkillsView()
                default: FocusQueueView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ForgeTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .environment(aiService)
    }
}

// MARK: - Custom Tab Bar

struct ForgeTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, label: String)] = [
        ("scope", "FOCUS"),
        ("hammer.fill", "PROJECTS"),
        ("flame.fill", "SKILLS")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    Haptic.light()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 16, weight: selectedTab == index ? .bold : .regular))
                            .foregroundColor(selectedTab == index ? tabAccent(index) : .white.opacity(0.25))

                        Text(tabs[index].label)
                            .font(.system(size: 8, weight: .heavy, design: .monospaced))
                            .foregroundColor(selectedTab == index ? tabAccent(index) : .white.opacity(0.2))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .background(
                        selectedTab == index ?
                            tabAccent(index).opacity(0.08) : Color.clear
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            ZStack {
                Color.black.opacity(0.95)
                Rectangle()
                    .fill(Color.white.opacity(0.04))
            }
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5)
        }
    }

    func tabAccent(_ index: Int) -> Color {
        switch index {
        case 0:  return Color(red: 0.4, green: 0.8, blue: 1.0)
        case 1:  return Color.white
        case 2:  return Color(red: 1.0, green: 0.5, blue: 0.2)
        default: return .white
        }
    }
}
