# AI Assistant iPad Layout Redesign

## Goal

Improve the iPad AI assistant screen so the chat content becomes the primary workspace. The current three-column layout keeps both the app navigation and conversation list visible, which leaves the actual conversation with too little width.

## Approved Direction

Use a chat-first iPad layout:

- Keep a narrow icon rail on the far left for primary app navigation.
- Move the conversation/project list into an on-demand slide-over panel.
- Give the chat canvas most of the available width.
- Keep mode, model, and overflow actions in the chat toolbar.

## Layout Rules

### Primary Navigation

- Replace the wide left navigation with a compact icon rail.
- Width target: 64-72 pt.
- Items: Home, AI Assistant, Writing, Profile.
- Show selected state clearly.
- Text labels should not occupy permanent horizontal space.

### Conversation List

- Conversation list should not be a permanent second column in the default chat view.
- Open it from a top toolbar button such as "Conversations" or a folder icon.
- Present it as a slide-over drawer or lightweight panel from the left.
- Selecting a conversation should switch the chat and dismiss the drawer.
- Folder, archived, pinned, and new conversation controls stay inside this panel.

### Chat Workspace

- The chat area is the main stage.
- Header shows the current conversation title.
- Top-right toolbar keeps:
  - learning mode segmented control
  - model selector
  - more actions
- Messages use the existing right-aligned user bubble and left-aligned assistant content pattern.
- Bottom input bar remains fixed and supports text, attachments, stop, and send.

## Responsive Behavior

- Full-width iPad landscape: icon rail is persistent; conversation list is on demand.
- iPad split view or narrower width: icon rail may collapse behind a sidebar button; chat stays usable.
- Drawer width should be bounded so it never takes more than about one third of the screen.

## Success Criteria

- A normal chat session shows one permanent left rail and one large chat canvas.
- The conversation list can be opened quickly but does not constantly occupy space.
- The UI still supports existing assistant features: streaming, attachments, folders, archive, pin, share, mode selection, and model selection.
- The design feels like an iPad productivity app, not a desktop admin panel squeezed onto iPad.

## Non-Goals

- No backend API changes.
- No changes to AI model routing.
- No redesign of the login module.
- No removal of existing assistant features.
