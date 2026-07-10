# Assistant Merged Sidebar UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the AI assistant's duplicated icon rail plus floating conversation drawer with one stable iPad product sidebar.

**Architecture:** Keep `AppRootView` as the app shell and refactor only the assistant screen. Add a small value model for sidebar sections, then compose `AssistantRootView` from focused sidebar rows, quick tasks, recent conversations, and the existing `ChatView`.

**Tech Stack:** SwiftUI, XCTest, existing `AssistantStore`, existing design tokens.

---

### Task 1: Sidebar Data Contract

**Files:**
- Create: `PersonalEnglishAI/Features/Assistant/Models/AssistantSidebarItem.swift`
- Test: `PersonalEnglishAITests/Features/Assistant/AssistantSidebarItemTests.swift`

- [ ] **Step 1: Write failing tests**

Verify the assistant sidebar exposes four learning scenes and four quick tasks in the intended product order.

- [ ] **Step 2: Run tests to verify failure**

Run: `cd apple && swift test --filter AssistantSidebarItemTests`

- [ ] **Step 3: Implement the model**

Add `AssistantSidebarScene` and `AssistantSidebarQuickTask` value types with static ordered arrays.

- [ ] **Step 4: Run tests to verify pass**

Run: `cd apple && swift test --filter AssistantSidebarItemTests`

### Task 2: Assistant Layout Refactor

**Files:**
- Modify: `PersonalEnglishAI/Features/Assistant/Views/AssistantRootView.swift`

- [ ] **Step 1: Replace drawer state with a regular-width split layout**

Use a manual `HStack` split: fixed/capped sidebar on the left, existing `ChatView` on the right.

- [ ] **Step 2: Add sidebar sections**

Render learning scenes, quick tasks, and recent conversations from the new model plus `store.visibleConversations`.

- [ ] **Step 3: Preserve actions**

Keep new conversation creation, selected conversation switching, folder filtering, archived toggle, and conversation search.

- [ ] **Step 4: Verify build**

Run: `cd apple && swift build`.

### Task 3: Verification

**Files:**
- Modify only if the build/test output requires it.

- [ ] **Step 1: Run focused tests**

Run assistant and app tab tests.

- [ ] **Step 2: Run full Swift verification**

Run: `cd apple && swift build && swift test`.

- [ ] **Step 3: Run simulator**

Launch the app and inspect that AI assistant opens with one merged sidebar and a usable chat area.
