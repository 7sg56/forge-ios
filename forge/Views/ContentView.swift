import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var aiService = AIService.shared
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                mainContent
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }

    var mainContent: some View {
        ZStack(alignment: .bottom) {
            // Kill white overscroll on edges
            Color.black.ignoresSafeArea()

            // Swipeable page content
            TabView(selection: $selectedTab) {
                FocusQueueView()
                    .tag(0)

                HomeView()
                    .tag(1)

                SkillsView()
                    .tag(2)

                StatsView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)
            .ignoresSafeArea()
            .background(Color.black)

            ForgeTabBar(selectedTab: $selectedTab)
        }
        .background(Color.black)
        .ignoresSafeArea(.keyboard)
        .environment(aiService)
    }
}

// MARK: - Splash Screen

struct SplashScreen: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var lineWidth: CGFloat = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        ZStack {
            ForgeTheme.pureBlack.ignoresSafeArea()

            VStack(spacing: 28) {
                // Forge icon mark
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(ForgeTheme.aiAccent.opacity(0.15), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(logoScale * 1.3)

                    // Inner ring
                    Circle()
                        .stroke(ForgeTheme.aiAccent.opacity(0.4), lineWidth: 1)
                        .frame(width: 72, height: 72)

                    // Icon
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(ForgeTheme.aiAccent)
                        .rotationEffect(.degrees(-15))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 12) {
                    Text("FORGE")
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundColor(ForgeTheme.onSurface)
                        .tracking(12)
                        .opacity(textOpacity)

                    // Horizontal accent line
                    Rectangle()
                        .fill(ForgeTheme.aiAccent)
                        .frame(width: lineWidth, height: 2)

                    Text("DEVELOPER GROWTH OS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(ForgeTheme.aiAccent.opacity(0.6))
                        .tracking(4)
                        .opacity(subtitleOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                lineWidth = 80
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                subtitleOpacity = 1.0
            }
        }
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
                            .foregroundColor(selectedTab == index ? ForgeTheme.aiAccent : ForgeTheme.outline)
                            .offset(y: selectedTab == index ? -2 : 0) // hover effect equivalent

                        Text(tabs[index].label)
                            .font(Font.forgeLabelCaps)
                            .foregroundColor(selectedTab == index ? ForgeTheme.aiAccent : ForgeTheme.outline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(ForgeTheme.pureBlack)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ForgeTheme.border)
                .frame(height: 1)
        }
    }
}
