# Roadmap

This roadmap describes the intended path for building the iPadOS client. Completed work is recorded in `phase-log.md`, and the detailed planning reference remains in `ipados-development-plan.md`.

## Guiding Direction

- Build a native SwiftUI iPadOS client.
- Reuse the existing `LiMing0016/personalenglishai` backend, database, and AI orchestrator.
- Do not store OpenAI API keys in the iPad app.
- Prioritize a useful learning assistant workflow before broader feature coverage.

## Phase 0: App Skeleton

Status: complete.

Scope:

- Xcode project
- SwiftUI app entry
- iPad three-column root layout
- feature folders
- mock Home, Assistant, Writing, and Profile surfaces
- basic API client and auth storage placeholders

## Phase 1: Auth And Session

Status: next.

Scope:

- confirm mobile refresh-token strategy
- implement `AuthService`
- sign in with existing backend account
- store access token in Keychain
- restore session on launch
- fetch `/api/users/me/profile`

## Phase 2: Learning Assistant MVP

Status: in progress.

Scope:

- list conversations
- create conversation
- load messages
- send message
- support non-streaming response first
- add streaming response after the basic loop works
- current focus: [AI Assistant P0 Stability Loop](./ai-assistant-p0)
- P1 chat experience: [AI Assistant P1 Core Chat Experience](./ai-assistant-p1)

## Phase 3: Writing MVP

Status: planned.

Scope:

- writing editor
- free/exam writing modes
- submit essay for evaluation
- display score and feedback
- local draft persistence

## Phase 4: iPadOS Experience

Status: planned.

Scope:

- landscape and portrait polish
- keyboard shortcuts
- Split View and Stage Manager handling
- loading, empty, and error state refinement
- accessibility pass

## Phase 5: Profile And Subscription

Status: planned.

Scope:

- profile details
- learning stats
- ability profile
- subscription status
- quota usage

## Phase 6: Release Readiness

Status: planned.

Scope:

- app icon and metadata
- privacy notes
- TestFlight readiness
- real-device testing
- App Store review risk check
