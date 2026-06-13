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
        .navigationTitle("首页")
    }
}

private struct HeaderSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("学习工作台")
                .font(Typography.pageTitle)
            Text("从一次对话、一篇写作草稿，或最近的学习进度开始。")
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
            Text("今日")
                .font(Typography.sectionTitle)
            EmptyStateView(
                systemImage: "sparkles",
                title: "准备好了就开始",
                message: "当前阶段使用示例内容。登录和 API 接入完成后，这里会展示真实学习数据。"
            )
            .frame(height: 260)
            .background(Color.peaiSurface, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct DashboardContextView: View {
    var body: some View {
        List {
            Section("工作台") {
                Label("总览", systemImage: "house")
                Label("最近活动", systemImage: "clock")
                Label("草稿", systemImage: "doc.text")
            }
        }
        .navigationTitle("首页")
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
            title: "问 AI 助手",
            subtitle: "练口语、讲语法、做翻译，也可以一起整理想法。",
            systemImage: "bubble.left.and.bubble.right"
        ),
        DashboardQuickAction(
            id: "writing",
            title: "写一篇作文",
            subtitle: "先完成草稿，后续接入 AI 评分与反馈。",
            systemImage: "pencil.and.scribble"
        ),
        DashboardQuickAction(
            id: "profile",
            title: "查看学习档案",
            subtitle: "追踪能力变化、学习进度和账户状态。",
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
