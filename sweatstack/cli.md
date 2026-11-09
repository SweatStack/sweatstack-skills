# SweatStack CLI

Command-line tool for authentication, app management, and hosting static sites on SweatStack Pages.

## Contents

- [Installation](#installation)
- [Running Non-Interactively](#running-non-interactively)
- [Authentication](#authentication)
- [Project Configuration](#project-configuration)
- [Create an Application](#create-an-application)
- [Preview Locally](#preview-locally)
- [Deploy](#deploy)
- [Going Live](#going-live)

## Installation

**macOS/Linux:**
```bash
curl -LsSf sweatstack.no/install-cli | sh
```

**Windows:**
```powershell
powershell -ExecutionPolicy ByPass -c "irm sweatstack.no/install-cli-windows | iex"
```

Verify with `sweatstack --version`. Alternative: `uv tool install sweatstack-cli`

## Running Non-Interactively

Commands run without a terminal never prompt: missing input is an error instead. Pass every value as an argument or flag.

| Exit code | Meaning |
|-----------|---------|
| `0` | Success |
| `1` | Invalid input or local problem (missing argument, existing file, missing directory) |
| `2` | Not authenticated |
| `3` | API error (e.g. page name rejected) |

## Authentication

```bash
sweatstack status    # Auth status, user, and whether a CLI update is available
sweatstack login     # Opens the browser to sign in, then stores credentials
sweatstack logout    # Remove stored credentials
```

Run `sweatstack status` first. If not authenticated, ask the user to run `sweatstack login`: it needs them to sign in in their browser. If `status` reports an update, run the upgrade command it prints.

Creating an app or changing its page can also exit `2` with a message that it needs the user's passkey. Ask the user to do what the message says (`sweatstack login` confirms the passkey in their browser), then run the command again.

## Project Configuration

`sweatstack.toml` links a directory to an application and its page. Every `page` command reads its defaults from it.

```toml
[app]
name = "My App"
client_id = "abc123"

[page]
slug = "my-app"
directory = "public"
```

`app create`, `app link` and `page init` write this file. When the user provides a `client_id`, write it yourself with the format above.

## Create an Application

```bash
sweatstack app create "My App" --page my-app
```

Creates a private application and its page at `https://my-app.pages.sweatstack.dev`, and writes `sweatstack.toml` with `directory = "public"`. The client ID is printed and recorded in `sweatstack.toml`.

| Flag | Purpose |
|------|---------|
| `--page`, `-p SLUG` | Create the app's page too, and register its sign-in redirects |
| `--description`, `-d TEXT` | App description (max 500 characters) |
| `--secret`, `-s` | Generate a client secret (server-side apps only; browser apps use PKCE) |
| `--env` / `--env-file PATH` | Write the credentials to `.env` or a given file |
| `--json` | Print the created app as JSON |

- **Always pass `--page`** for an app that will be hosted on Pages. It registers both `https://<slug>.pages.sweatstack.dev` and `http://localhost` (any port) as redirect URIs, so sign-in works live and in local previews.
- **Page names (slugs):** 3–63 lowercase letters, numbers, and hyphens, without "sweatstack". Names can also be taken or reserved. A rejected name exits with code `3` and creates nothing: choose another name and retry.
- **Check for `sweatstack.toml` first.** If it exists, the directory is already linked: use its `client_id` instead of creating an app. `app create` refuses to overwrite it.

### Scaffold a Starter App

```bash
sweatstack page init "My App"
```

Like `app create --page`, but also writes `public/index.html`: a working starter app that signs in and plots the user's latest activity. Use it when the user wants a starting point rather than a custom-built app. Options: `--slug`, `--dir`, `--title`, `--client-id` (reuse an existing app), `--force` (overwrite `index.html`).

### Link an Existing Application

`sweatstack app link` lists the user's applications and asks which one to link. It only works interactively. Non-interactively, write `sweatstack.toml` yourself.

## Preview Locally

```bash
sweatstack page serve
```

Serves the `[page] directory` on the first free port from 8000 and prints its URL. It keeps running: start it in the background, or ask the user to run it. Open it at `http://localhost:<port>`, not `127.0.0.1`, because the redirect URI must match the hostname.

## Deploy

```bash
sweatstack page deploy                         # Uses sweatstack.toml
sweatstack page deploy my-app --dir ./public   # Explicit slug and directory
```

Uploads the directory to `https://<slug>.pages.sweatstack.dev`. Every deploy replaces all files on the page.

- **Page doesn't exist yet:** with an app linked in `sweatstack.toml`, `deploy` creates its page. Without a linked app, it fails non-interactively: create the app with `app create --page` first.
- **Sign-in on the live page** needs `https://<slug>.pages.sweatstack.dev` in the app's redirect URIs. Creating the app with its page (`app create --page`, or `page init` without an existing app) registers it. A page added to an existing app doesn't: have the user add it on the app's OAuth tab, `https://app.sweatstack.no/applications/{client_id}/oauth`, together with `http://localhost`, because setting any redirect URI ends the default localhost access.
- **Limits:** 10 MB per file; 100 MB and about 1,000 files per deploy.

## Going Live

New apps are private: only the developer can sign in. After a deploy, the CLI prints what the app still needs before anyone else can connect (a description, a logo, a purpose for each kind of data it uses, ...) and a link to the app's Consent screen: `https://app.sweatstack.no/applications/{client_id}/consent`. `app create --json` and the deploy response carry the same list as `go_live_missing`. Surface it to the user when they're ready for others to use the app; a browser-only Pages app can take the Pages fast track there.

The list only covers the data ticked on the Consent screen tab, which for a new app is activities. If the app requests another category, have the user tick it there too, or everyone else is refused.
