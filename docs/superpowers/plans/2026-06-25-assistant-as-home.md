# Assistant As Home Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make AI Assistant the default post-login iPadOS entry while keeping the current Dashboard code available for future learning analytics.

**Architecture:** Keep `AppTab.dashboard` as an internal route, but introduce a visible primary navigation list that excludes it. `AppShellView` should initialize on `.assistant`, and the rail should render only assistant, writing, and profile.

**Tech Stack:** SwiftUI, XCTest, XcodeBuildMCP simulator build/test.

---

### Task 1: Define Visible Primary Tabs

**Files:**
- Modify: `PersonalEnglishAI/App/AppTab.swift`
- Test: `PersonalEnglishAITests/App/AppTabTests.swift`

- [ ] **Step 1: Add tests for primary navigation semantics**

Create `PersonalEnglishAITests/App/AppTabTests.swift`:

```swift
import XCTest
@testable import PersonalEnglishAI

final class AppTabTests: XCTestCase {
    func testPrimaryTabsStartWithAssistant() {
        XCTAssertEqual(AppTab.primaryTabs.first, .assistant)
    }

    func testPrimaryTabsExcludeDashboard() {
        XCTAssertFalse(AppTab.primaryTabs.contains(.dashboard))
    }

    func testPrimaryTabsKeepMainProductAreas() {
        XCTAssertEqual(AppTab.primaryTabs, [.assistant, .writing, .profile])
    }
}
```

- [ ] **Step 2: Run test to verify it fails before implementation**

Run:

```bash
xcodebuild test -project PersonalEnglishAI.xcodeproj -scheme PersonalEnglishAI -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' -only-testing:PersonalEnglishAITests/AppTabTests
```

Expected: compile failure because `AppTab.primaryTabs` does not exist.

- [ ] **Step 3: Add `primaryTabs` to `AppTab`**

Update `PersonalEnglishAI/App/AppTab.swift`:

```swift
static let primaryTabs: [AppTab] = [.assistant, .writing, .profile]
```

- [ ] **Step 4: Run test to verify it passes**

Run the same `xcodebuild test` command.

Expected: `3 passed, 0 failed`.

### Task 2: Make Assistant The Default Shell Entry

**Files:**
- Modify: `PersonalEnglishAI/App/AppRootView.swift`

- [ ] **Step 1: Change initial selected tab**

Update `AppShellView`:

```swift
@State private var selectedTab: AppTab = .assistant
```

- [ ] **Step 2: Render only primary tabs in the rail**

Update `PrimaryRailView`:

```swift
ForEach(AppTab.primaryTabs) { tab in
    Button {
        selectedTab = tab
    } label: {
        Image(systemName: tab.systemImage)
            .font(.title2)
            .foregroundStyle(selectedTab == tab ? Color.peaiAccent : .primary)
            .frame(width: 48, height: 48)
            .background(
                selectedTab == tab ? Color.peaiAccent.opacity(0.14) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
    }
    .buttonStyle(.plain)
    .accessibilityLabel(tab.title)
    .accessibilityIdentifier("sidebar.\(tab.rawValue)")
}
```

- [ ] **Step 3: Keep dashboard route handling**

Do not remove this switch branch:

```swift
case .dashboard:
    DashboardView { tab in
        selectedTab = tab
    }
```

This preserves the future Dashboard route without exposing it in the main rail.

### Task 3: Verify iPadOS Behavior

**Files:**
- Verify: `PersonalEnglishAI/App/AppTab.swift`
- Verify: `PersonalEnglishAI/App/AppRootView.swift`

- [ ] **Step 1: Build the app**

Run via XcodeBuildMCP:

```text
build_sim(extraArgs: ["-quiet"])
```

Expected: build succeeds with 0 errors.

- [ ] **Step 2: Run app tab tests**

Run via XcodeBuildMCP:

```text
test_sim(extraArgs: ["-only-testing:PersonalEnglishAITests/AppTabTests"], progress: false)
```

Expected: `3 passed, 0 failed`.

- [ ] **Step 3: Launch the app and inspect the UI**

Run via XcodeBuildMCP:

```text
build_run_sim()
```

Expected: after authenticated session is active, the app opens on AI Assistant and the left rail shows assistant, writing, and profile without the Home icon.
