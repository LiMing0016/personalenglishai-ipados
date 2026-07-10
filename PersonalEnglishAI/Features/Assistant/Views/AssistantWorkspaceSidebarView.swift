import SwiftUI

struct AssistantWorkspaceSidebarView: View {
    @ObservedObject var store: AssistantStore
    @Binding var selectedConversationID: AssistantConversation.ID?
    let selectedScene: AssistantSidebarScene
    let selectScene: (AssistantSidebarScene) -> Void
    let toggleCollapsed: () -> Void
    let createConversation: () -> Void
    let runQuickTask: (AssistantSidebarQuickTask) -> Void

    private var recentConversations: [AssistantConversation] {
        Array(store.visibleConversations.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    sceneSection
                    quickTaskSection
                    filterSection
                    recentSection
                }
                .padding(.bottom, Spacing.lg)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.peaiSurface)
    }

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            AssistantSidebarIconButton(
                systemImage: "sidebar.leading",
                title: "折叠侧栏",
                isSelected: false,
                action: toggleCollapsed
            )
            .accessibilityIdentifier("assistant.sidebar.toggle")

            VStack(alignment: .leading, spacing: 4) {
                Text("Personal English AI")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text("英语学习工作台")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                createConversation()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.headline.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("新建对话")
            .accessibilityIdentifier("assistant.sidebar.newConversation")
        }
    }

    private var sceneSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SidebarSectionTitle("学习场景")

            ForEach(AssistantSidebarScene.allCases) { scene in
                Button {
                    selectScene(scene)
                } label: {
                    AssistantSceneRow(
                        scene: scene,
                        isSelected: scene == selectedScene
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("assistant.scene.\(scene.rawValue)")
            }
        }
    }

    private var quickTaskSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SidebarSectionTitle("快捷任务")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Spacing.sm),
                    GridItem(.flexible(), spacing: Spacing.sm)
                ],
                spacing: Spacing.sm
            ) {
                ForEach(AssistantSidebarQuickTask.allCases) { task in
                    Button {
                        runQuickTask(task)
                    } label: {
                        Text(task.title)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(.systemBackground), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(store.isSending)
                    .accessibilityIdentifier("assistant.quickTask.\(task.rawValue)")
                }
            }
        }
    }

    private var filterSection: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Picker("文件夹", selection: $store.selectedProjectID) {
                    Text("全部对话").tag(Int?.none)
                    ForEach(store.projects) { project in
                        Text(project.name).tag(Optional(project.id))
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Toggle("归档", isOn: $store.showingArchived)
                    .labelsHidden()
            }

            HStack(spacing: Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                TextField("搜索对话", text: $store.conversationSearchQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, Spacing.sm)
            .frame(height: 42)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(.separator).opacity(0.18), lineWidth: 1)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SidebarSectionTitle(store.showingArchived ? "归档对话" : "最近对话")

            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            } else if recentConversations.isEmpty {
                Text("还没有对话")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .background(Color(.systemBackground).opacity(0.64), in: RoundedRectangle(cornerRadius: 18))
            } else {
                VStack(spacing: 0) {
                    ForEach(recentConversations) { conversation in
                        Button {
                            selectedConversationID = conversation.id
                        } label: {
                            AssistantRecentConversationRow(
                                conversation: conversation,
                                isSelected: selectedConversationID == conversation.id
                            )
                        }
                        .buttonStyle(.plain)

                        if conversation.id != recentConversations.last?.id {
                            Divider()
                                .padding(.leading, Spacing.md)
                        }
                    }
                }
                .background(Color(.systemBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }
}

private struct SidebarSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.6)
    }
}

private struct AssistantSidebarIconButton: View {
    let systemImage: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isSelected ? Color.peaiAccent : .primary)
                .frame(width: 44, height: 44)
                .background(background, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var background: Color {
        isSelected ? Color.peaiAccent.opacity(0.14) : Color(.systemBackground)
    }

    private var strokeColor: Color {
        isSelected ? Color.peaiAccent.opacity(0.20) : Color(.separator).opacity(0.14)
    }
}

private struct AssistantSceneRow: View {
    let scene: AssistantSidebarScene
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: scene.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isSelected ? Color.peaiAccent : .primary)
                .frame(width: 44, height: 44)
                .background(iconBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(scene.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(scene.subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.sm)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.peaiAccent.opacity(0.18) : Color(.separator).opacity(0.16), lineWidth: 1)
        }
    }

    private var iconBackground: Color {
        isSelected ? Color.peaiAccent.opacity(0.14) : Color(.systemBackground)
    }

    private var rowBackground: Color {
        isSelected ? Color.peaiAccent.opacity(0.12) : Color(.systemBackground).opacity(0.64)
    }
}

private struct AssistantRecentConversationRow: View {
    let conversation: AssistantConversation
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: Spacing.xs) {
                if conversation.pinned {
                    Image(systemName: "pin.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.peaiAccent)
                }

                Text(conversation.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Text(conversation.summary?.isEmpty == false ? conversation.summary! : "暂无摘要")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(isSelected ? Color.peaiAccent.opacity(0.10) : Color.clear)
    }
}
