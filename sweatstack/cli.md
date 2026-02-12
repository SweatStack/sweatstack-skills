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
sweatstack status    # Show auth status and token details
```

Always `sweatstack status` to check if the user is authenticated.

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

## Deploy Static Sites

```bash
sweatstack page deploy myapp ./dist
```

Uploads files to `https://myapp.sweatstack.pages.dev`.

**Constraints:**
- Pages must be pre-created via dashboard: https://app.sweatstack.no/settings/api
- 10MB limit per app

## Help

```bash
sweatstack --help
sweatstack app --help
sweatstack app create --help
```
