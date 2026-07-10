import SwiftUI

struct ConversationListView: View {
    @ObservedObject var store: AssistantStore
    @Binding var selectedConversationID: AssistantConversation.ID?
    var onSelectConversation: (() -> Void)?
    @State private var showingFolderEditor = false
    @State private var folderName = ""
    @State private var movingConversationID: AssistantConversation.ID?
    @State private var renamingConversationID: AssistantConversation.ID?
    @State private var conversationTitle = ""

    var body: some View {
        List {
            Section {
                Picker("文件夹", selection: $store.selectedProjectID) {
                    Text("全部对话").tag(Int?.none)
                    ForEach(store.projects) { project in
                        Text(project.name).tag(Optional(project.id))
                    }
                }
                .pickerStyle(.menu)

                Toggle("显示归档", isOn: $store.showingArchived)
            }

            if store.isLoading {
                LoadingView(title: "正在加载对话")
            } else if store.visibleConversations.isEmpty {
                EmptyStateView(systemImage: "bubble.left", title: "没有对话", message: "新建一个对话开始练习。")
                    .listRowSeparator(.hidden)
            } else {
                Section(store.showingArchived ? "归档对话" : "最近对话") {
                    ForEach(store.visibleConversations) { conversation in
                        ConversationRowView(conversation: conversation)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedConversationID = conversation.id
                                onSelectConversation?()
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    Task { await store.setPinned(conversationID: conversation.id, pinned: !conversation.pinned) }
                                } label: {
                                    Label(conversation.pinned ? "取消置顶" : "置顶", systemImage: conversation.pinned ? "pin.slash" : "pin")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await store.delete(conversationID: conversation.id) }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }

                                Button {
                                    Task {
                                        if conversation.archived {
                                            await store.restore(conversationID: conversation.id)
                                        } else {
                                            await store.archive(conversationID: conversation.id)
                                        }
                                    }
                                } label: {
                                    Label(conversation.archived ? "恢复" : "归档", systemImage: conversation.archived ? "tray.and.arrow.up" : "archivebox")
                                }
                                .tint(.orange)
                            }
                            .contextMenu {
                                Button("重命名对话", systemImage: "pencil") {
                                    conversationTitle = conversation.title
                                    renamingConversationID = conversation.id
                                }
                                Button(conversation.pinned ? "取消置顶" : "置顶", systemImage: conversation.pinned ? "pin.slash" : "pin") {
                                    Task { await store.setPinned(conversationID: conversation.id, pinned: !conversation.pinned) }
                                }
                                Button("移动到文件夹", systemImage: "folder") {
                                    movingConversationID = conversation.id
                                }
                                Button(conversation.archived ? "恢复对话" : "归档对话", systemImage: conversation.archived ? "tray.and.arrow.up" : "archivebox") {
                                    Task {
                                        if conversation.archived {
                                            await store.restore(conversationID: conversation.id)
                                        } else {
                                            await store.archive(conversationID: conversation.id)
                                        }
                                    }
                                }
                                Button("删除对话", systemImage: "trash", role: .destructive) {
                                    Task { await store.delete(conversationID: conversation.id) }
                                }
                            }
                            .listRowBackground(selectedConversationID == conversation.id ? Color.accentColor.opacity(0.14) : Color.clear)
                            .accessibilityIdentifier("assistant.conversation.\(conversation.id)")
                    }
                }
            }
        }
        .alert("重命名对话", isPresented: Binding(
            get: { renamingConversationID != nil },
            set: {
                if !$0 {
                    renamingConversationID = nil
                    conversationTitle = ""
                }
            }
        )) {
            TextField("对话标题", text: $conversationTitle)
            Button("取消", role: .cancel) {
                renamingConversationID = nil
                conversationTitle = ""
            }
            Button("保存") {
                if let renamingConversationID {
                    Task { await store.renameConversation(id: renamingConversationID, title: conversationTitle) }
                }
                renamingConversationID = nil
                conversationTitle = ""
            }
        }
        .navigationTitle("AI 助手")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button("新建文件夹", systemImage: "folder.badge.plus") {
                        folderName = ""
                        showingFolderEditor = true
                    }

                    if let selectedProjectID = store.selectedProjectID,
                       let project = store.projects.first(where: { $0.id == selectedProjectID }) {
                        Button("重命名“\(project.name)”", systemImage: "pencil") {
                            folderName = project.name
                            showingFolderEditor = true
                        }
                        Button("删除当前文件夹", systemImage: "trash", role: .destructive) {
                            Task { await store.deleteProject(id: selectedProjectID) }
                        }
                    }
                } label: {
                    Image(systemName: "folder")
                }
                .accessibilityLabel("文件夹")

                Button {
                    Task {
                        if let id = await store.createConversation() {
                            selectedConversationID = id
                            onSelectConversation?()
                        }
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("新建对话")
                .accessibilityIdentifier("assistant.newConversation")
            }
        }
        .task {
            selectedConversationID = await store.loadInitialSelection(currentSelection: selectedConversationID)
        }
        .searchable(text: $store.conversationSearchQuery, prompt: "搜索对话、摘要或内容")
        .refreshable {
            await store.load()
        }
        .alert("文件夹", isPresented: $showingFolderEditor) {
            TextField("文件夹名称", text: $folderName)
            Button("取消", role: .cancel) {}
            Button("保存") {
                Task {
                    if let selectedProjectID = store.selectedProjectID,
                       store.projects.contains(where: { $0.id == selectedProjectID }) {
                        await store.renameProject(id: selectedProjectID, name: folderName)
                    } else {
                        await store.createProject(name: folderName)
                    }
                }
            }
        }
        .confirmationDialog("移动到文件夹", isPresented: Binding(
            get: { movingConversationID != nil },
            set: { if !$0 { movingConversationID = nil } }
        )) {
            Button("不放入文件夹") {
                if let movingConversationID {
                    Task { await store.move(conversationID: movingConversationID, projectId: nil) }
                }
                movingConversationID = nil
            }
            ForEach(store.projects) { project in
                Button(project.name) {
                    if let movingConversationID {
                        Task { await store.move(conversationID: movingConversationID, projectId: project.id) }
                    }
                    movingConversationID = nil
                }
            }
        }
        .alert("提示", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.clearError() } }
        )) {
            Button("知道了", role: .cancel) { store.clearError() }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

private struct ConversationRowView: View {
    let conversation: AssistantConversation

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                if conversation.pinned {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(Color.peaiAccent)
                }
                Text(conversation.title)
                    .font(.headline)
                    .lineLimit(1)
            }
            Text(conversation.summary?.isEmpty == false ? conversation.summary! : "暂无摘要")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.xs)
    }
}

struct ConversationListView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationListPreview()
    }
}

private struct ConversationListPreview: View {
    @State private var selectedConversationID: AssistantConversation.ID?

    var body: some View {
        NavigationStack {
            ConversationListView(
                store: AssistantStore(service: MockAssistantService(), shareBaseURL: URL(string: "https://example.com")!),
                selectedConversationID: $selectedConversationID,
                onSelectConversation: nil
            )
        }
    }
}
