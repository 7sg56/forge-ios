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
                case 3:  StatsView()
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
        ("scope", "Focus"),
        ("folder", "Projects"),
        ("terminal", "Skills"),
        ("chart.bar.xaxis", "Stats")
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
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 18, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? Color(red: 0.4, green: 0.8, blue: 1.0) : .white.opacity(0.4))
                            .offset(y: selectedTab == index ? -2 : 0) // hover effect equivalent

                        Text(tabs[index].label)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(selectedTab == index ? Color(red: 0.4, green: 0.8, blue: 1.0) : .white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(red: 0.04, green: 0.04, blue: 0.04)) // #0a0a0a
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(white: 0.13)) // #222222
                .frame(height: 1)
        }
    }
}
