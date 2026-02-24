# SweatStack CLI

Command-line tool for authentication, app management, and static deployments.

## Installation

**macOS/Linux:**
```bash
curl -LsSf sweatstack.no/install-cli | sh
```

**Windows:**
```powershell
powershell -ExecutionPolicy ByPass -c "irm sweatstack.no/install-cli-windows | iex"
```

Verify with `sweatstack --version`. Alternative: `uv pip install sweatstack-cli`

## Authentication

```bash
sweatstack login     # Opens browser for OAuth2, stores credentials locally
sweatstack logout    # Remove stored credentials
sweatstack status    # Show authentication and version status
```

Always `sweatstack status` to check if the user is authenticated.

## Project Configuration

The CLI uses `sweatstack.toml` to store project configuration. Created automatically by `sweatstack app create` or `sweatstack app link`.

```toml
[app]
name = "My App"
client_id = "abc123"

[page]
slug = "my-page"
directory = "dist"
```

When present, commands like `sweatstack page deploy` read defaults from this file — no arguments needed.

## Create Applications

```bash
sweatstack app create "My App"
```

**Options:**

| Flag | Purpose |
|------|---------|
| `--page myapp` | Associate with a SweatStack Page (auto-configures redirect URI) |
| `--secret` | Generate client secret for confidential clients |
| `--env` | Write credentials to `.env` file |
| `--env-file PATH` | Write credentials to specific file |
| `--json` | Output as JSON for scripting |

**Full example:**
```bash
sweatstack app create "My Streamlit App" --page my-streamlit-app --secret --env-file .env.local
```

Creates a private application. Public apps require the web dashboard. Page slugs can be rejected if unavailable.

### Link Existing Application

```bash
sweatstack app link
```

Prompts to select from existing applications and creates `sweatstack.toml` in the current directory.

## Deploy Static Sites

```bash
# With sweatstack.toml in the directory
sweatstack page deploy

# Or specify explicitly
sweatstack page deploy myapp ./dist
```

Uploads files to `https://myapp.pages.sweatstack.dev`.

**Constraints:**
- Pages must be pre-created via dashboard: https://app.sweatstack.no/settings/api
- 10MB limit per app

## Help

```bash
sweatstack --help
sweatstack app --help
sweatstack app create --help
```
