# SweatStack Skills

[Agent Skills](https://agentskills.io) for building apps with [SweatStack](https://sweatstack.no), the sports data platform for developers.

## What's this?

Skills are instruction manuals that AI coding assistants can read. Install once, and your AI assistant knows how to work with SweatStack: OAuth flows, API endpoints, data formats, all of it.

Once installed, just ask your AI assistant things like:

- *"Build me a SweatStack app that shows my recent activities"*
- *"Create a training zone calculator using SweatStack"*

This repo contains skills for developing with SweatStack. For example, quickly building single-file HTML web apps that visualize your sports data.

## What's included

The [`sweatstack`](sweatstack/) skill includes:

| Guide | Description |
|-------|-------------|
| [webapp-guide.md](sweatstack/webapp-guide.md) | Building single-file HTML web apps. Covers OAuth PKCE, styling, branding, deployment. |
| [api.md](sweatstack/api.md) | API reference. Endpoints, Parquet parsing, metrics, common gotchas. |

## Installation

### Claude.ai

Upload the skill ZIP in Settings → Features → Skills.

See [Using Skills in Claude](https://support.claude.com/en/articles/12512180-using-skills-in-claude) for details.

### Claude Code

Copy the `sweatstack/` folder to `~/.claude/skills/` (personal) or `.claude/skills/` (project).

See [Skills in Claude Code](https://code.claude.com/docs/en/skills) for details.

### Other tools

Agent Skills are an [open format](https://agentskills.io) supported by Cursor, VS Code, and others. Check your tool's docs.

## Prerequisites

You'll need a SweatStack account and a registered app to get a Client ID. Create one at [app.sweatstack.no/applications/new](https://app.sweatstack.no/applications/new).

## Learn more

- [Agent Skills overview](https://claude.com/skills)
- [SweatStack](https://sweatstack.no)
- [agentskills.io](https://agentskills.io)

## About

SweatStack is built by one person who got tired of rebuilding fitness data infrastructure. These skills make it easier to get started. Issues and suggestions welcome.
