# Writing Hub Entry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the iPadOS Writing tab open a Writing Hub first, then navigate into the existing immersive editor.

**Architecture:** Add a small value-state model for hub tabs, filters, sorting, and draft summaries. Build `WritingHubView` as the writing module entry, and keep `WritingRootView` as the editor destination pushed from the hub.

**Tech Stack:** SwiftUI, XCTest, existing `WritingRootView`, existing app rail navigation.

---

### Task 1: Hub State Model

**Files:**
- Create: `PersonalEnglishAI/Features/Writing/Models/WritingHubState.swift`
- Test: `PersonalEnglishAITests/Features/Writing/WritingHubStateTests.swift`

- [ ] Write tests for default practice tab, search and mode filtering, sorting, and dashboard summary.
- [ ] Implement value models: `WritingHubSection`, `WritingDocumentModeFilter`, `WritingDocumentStatus`, `WritingDocumentSummary`, and `WritingHubState`.
- [ ] Run writing model tests.

### Task 2: Hub UI

**Files:**
- Create: `PersonalEnglishAI/Features/Writing/Views/WritingHubView.swift`
- Modify: `PersonalEnglishAI/App/AppRootView.swift`

- [ ] Build a hub screen with Practice/Dashboard tabs, action cards, history search/filter/sort, and document cards.
- [ ] Push `WritingRootView` from free writing, exam writing, and history cards.
- [ ] Change the app Writing tab to show `WritingHubView`.

### Task 3: Verification

**Files:**
- Existing app and test targets

- [ ] Run targeted writing tests.
- [ ] Run full app build.
- [ ] Run full app tests when build succeeds.
