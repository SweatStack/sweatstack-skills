# SweatStack Skills

[Agent Skills](https://agentskills.io) for building apps with [SweatStack](https://sweatstack.no), the sports data platform for developers.

## Install

**Claude Code** (current project):
```sh
curl -LsSf https://sweatstack.no/install-skills | sh
```

**Claude Code** (global, all projects):
```sh
curl -LsSf https://sweatstack.no/install-skills | sh -s -- --global
```

**Claude.ai**: Zip the `sweatstack/` folder and upload in Settings → Features → Skills.

**Windows**: Use [Git Bash](https://git-scm.com/download/win) or WSL.

The install URL redirects to [`install.sh`](install.sh). Inspect it before running.

## What's this?

Skills are instruction manuals that AI coding assistants can read. Install once, and your AI assistant knows how to work with SweatStack: OAuth flows, API endpoints, data formats, all of it.

Once installed, just ask your AI assistant things like:

- *"Build me a SweatStack app that shows my recent activities"*
- *"Create a training zone calculator using SweatStack"*

## What's included

The [`sweatstack`](sweatstack/) skill covers:

| Guide | Description |
|-------|-------------|
| [webapp-guide.md](sweatstack/webapp-guide.md) | Building single-file HTML web apps. OAuth PKCE, styling, branding, deployment. |
| [api.md](sweatstack/api.md) | API reference. Endpoints, Parquet parsing, metrics, common gotchas. |

## Prerequisites

You'll need a SweatStack account and a registered app to get a Client ID. Create one at [app.sweatstack.no/applications/new](https://app.sweatstack.no/applications/new).

## Learn more

- [SweatStack](https://sweatstack.no)
- [Agent Skills](https://agentskills.io)

## About

SweatStack is built by one person who got tired of rebuilding fitness data infrastructure. These skills make it easier to get started. Issues and suggestions welcome.
