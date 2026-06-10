import SwiftUI

struct DashboardView: View {
    private let quickActions = DashboardQuickAction.samples

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HeaderSection()
                QuickActionsSection(actions: quickActions)
                TodayFocusSection()
            }
            .padding(Spacing.lg)
            .frame(maxWidth: 920, alignment: .leading)
        }
        .background(Color.peaiBackground)
        .navigationTitle("Home")
    }
}

private struct HeaderSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Learning workspace")
                .font(Typography.pageTitle)
            Text("Start with a conversation, draft an essay, or review your recent progress.")
                .font(Typography.body)
                .foregroundStyle(.secondary)
        }
    }
}

private struct QuickActionsSection: View {
    let actions: [DashboardQuickAction]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: Spacing.md, verticalSpacing: Spacing.md) {
            GridRow {
                ForEach(actions) { action in
                    QuickActionTile(action: action)
                }
            }
        }
    }
}

private struct QuickActionTile: View {
    let action: DashboardQuickAction

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Image(systemName: action.systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
            Text(action.title)
                .font(Typography.sectionTitle)
            Text(action.subtitle)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .background(Color.peaiSurface, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct TodayFocusSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today")
                .font(Typography.sectionTitle)
            EmptyStateView(
                systemImage: "sparkles",
                title: "Ready when you are",
                message: "Phase 0 uses mock content. Real learning data arrives after login and API integration."
            )
            .frame(height: 260)
            .background(Color.peaiSurface, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct DashboardContextView: View {
    var body: some View {
        List {
            Section("Workspace") {
                Label("Overview", systemImage: "house")
                Label("Recent activity", systemImage: "clock")
                Label("Drafts", systemImage: "doc.text")
            }
        }
        .navigationTitle("Home")
    }
}

private struct DashboardQuickAction: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String

    static let samples = [
        DashboardQuickAction(
            id: "assistant",
            title: "Ask assistant",
            subtitle: "Practice, explain, translate, and brainstorm.",
            systemImage: "bubble.left.and.bubble.right"
        ),
        DashboardQuickAction(
            id: "writing",
            title: "Write essay",
            subtitle: "Draft and prepare for AI scoring.",
            systemImage: "pencil.and.scribble"
        ),
        DashboardQuickAction(
            id: "profile",
            title: "Track profile",
            subtitle: "Review progress and subscription status.",
            systemImage: "chart.line.uptrend.xyaxis"
        )
    ]
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DashboardView()
        }
    }
}
