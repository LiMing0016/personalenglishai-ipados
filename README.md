# Personal English AI iPadOS

Personal English AI iPadOS is the native SwiftUI client for the Personal English AI project.

This repository owns only the iPadOS app. The existing Web, backend, database, and Python AI orchestrator remain in `LiMing0016/personalenglishai`.

## Documentation

The project roadmap and architecture docs are managed with VitePress.

Languages:

- Chinese: `docs/index.md`
- English: `docs/en/index.md`

Local docs commands:

```bash
npm install
npm run docs:dev
```

Build docs:

```bash
npm run docs:build
```

Note: `npm install` requires network access to the npm registry. If dependency installation has not run yet, `node_modules/` and `package-lock.json` will not exist.

## iPadOS Build

Current build verification command:

```bash
xcodebuild -quiet -project PersonalEnglishAI.xcodeproj -scheme PersonalEnglishAI -destination 'generic/platform=iOS Simulator' -derivedDataPath ./DerivedData build
```

## Project Memory

- `AGENTS.md`: long-term project rules for agents.
- `docs/roadmap.md`: product and engineering roadmap.
- `docs/phase-log.md`: completed work, open questions, and next steps.
- `docs/architecture.md`: app architecture notes.
- `docs/api-integration.md`: backend API integration notes.
