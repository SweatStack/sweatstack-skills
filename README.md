# SweatStack Skills

[Agent Skills](https://agentskills.io) for building apps with [SweatStack](https://sweatstack.no), the sports data platform for developers.

## Install

```sh
npx skills add SweatStack/sweatstack-skills
```

This works with Claude Code, Cursor, Codex, and [40+ other agents](https://github.com/vercel-labs/skills). Install globally with `-g`, or target a specific agent with `-a claude-code`.

**Claude.ai**: Zip the `sweatstack/` folder and upload in Settings → Features → Skills.

## What's this?

Skills are instruction manuals that AI coding assistants can read. Install once, and your AI assistant knows how to work with SweatStack: OAuth flows, API endpoints, data formats, all of it.

Once installed, just ask your AI assistant things like:

- *"Build me a SweatStack app that shows my recent activities"*
- *"Create a training zone calculator using SweatStack"*

## What's included

The [`sweatstack`](sweatstack/) skill covers:

| Guide | Description |
|-------|-------------|
| [webapp.md](sweatstack/webapp.md) | Building single-file HTML web apps. OAuth PKCE, styling, branding, deployment. |
| [auth.md](sweatstack/auth.md) | OAuth2/OpenID authentication. PKCE and authorization-code flows, tokens, redirect URIs. |
| [cli.md](sweatstack/cli.md) | The SweatStack CLI. App management and deployment. |
| [api.md](sweatstack/api.md) | API reference. Endpoints, Parquet parsing, metrics, common gotchas. |

## Prerequisites

You'll need a SweatStack account and a registered app to get a Client ID. Create one at [app.sweatstack.no/applications/new](https://app.sweatstack.no/applications/new).

## Learn more

- [SweatStack](https://sweatstack.no)
- [Agent Skills](https://agentskills.io)

## About

SweatStack is built by one person who got tired of rebuilding fitness data infrastructure. These skills make it easier to get started. Issues and suggestions welcome.
