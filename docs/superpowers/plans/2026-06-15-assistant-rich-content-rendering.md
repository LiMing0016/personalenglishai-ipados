# Assistant Rich Content Rendering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the iPad AI assistant rich content renderer for Markdown, Mermaid, and D3 graph-json blocks.

**Architecture:** Keep the chat shell in SwiftUI and render only assistant message bodies with a local `WKWebView`. Parse assistant content into typed blocks in Swift, pass a structured payload into a local HTML renderer, and receive height/link/render events through a narrow JS bridge.

**Tech Stack:** SwiftUI, WebKit, XCTest, local HTML/CSS/JS, markdown-it or marked, DOMPurify, Mermaid, D3.

---

### Task 1: Rich Content Parser

**Files:**
- Create: `PersonalEnglishAI/Features/Assistant/RichContent/RichContentBlock.swift`
- Create: `PersonalEnglishAI/Features/Assistant/RichContent/RichContentParser.swift`
- Test: `PersonalEnglishAITests/Features/Assistant/RichContentParserTests.swift`

- [ ] Add tests for Markdown, Mermaid, graph-json, and unknown fenced code blocks.
- [ ] Implement `RichContentBlock` and `RichContentParser`.
- [ ] Run `PersonalEnglishAITests/RichContentParserTests`.

### Task 2: Local Web Renderer Resources

**Files:**
- Create: `PersonalEnglishAI/Resources/RichRenderer/renderer.html`
- Create: `PersonalEnglishAI/Resources/RichRenderer/renderer.css`
- Create: `PersonalEnglishAI/Resources/RichRenderer/renderer.js`
- Create: `PersonalEnglishAI/Resources/RichRenderer/vendor/*.min.js`

- [ ] Add local HTML/CSS/JS renderer resources.
- [ ] Vendor `markdown-it`, `dompurify`, `mermaid`, and `d3`.
- [ ] Ensure renderer accepts a structured payload and reports height.

### Task 3: WKWebView Wrapper

**Files:**
- Create: `PersonalEnglishAI/Features/Assistant/RichContent/RichContentWebEvent.swift`
- Create: `PersonalEnglishAI/Features/Assistant/RichContent/MarkdownWebView.swift`
- Create: `PersonalEnglishAI/Features/Assistant/RichContent/AssistantRichMessageView.swift`
- Modify: `PersonalEnglishAI/Features/Assistant/Views/MessageBubbleView.swift`

- [ ] Implement the `WKWebView` wrapper and event bridge.
- [ ] Use `AssistantRichMessageView` for assistant messages only.
- [ ] Keep user messages as native SwiftUI text.

### Task 4: Verification

**Files:**
- Modify as needed based on build errors.

- [ ] Run parser tests.
- [ ] Run full iOS simulator tests.
- [ ] Build and run on iPad simulator.
- [ ] Verify no diff whitespace issues.
