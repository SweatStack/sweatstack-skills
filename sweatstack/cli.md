# SweatStack CLI

Command-line tool for authentication, app management, and static deployments.

## Installation

Requires Python 3.11+.

```bash
uvx sweatstack-cli               # Run directly
uv tool install sweatstack-cli    # Or install as a tool
pip install sweatstack-cli        # Or with pip
```

Verify with `sweatstack --version`.

## Authentication

```bash
sweatstack login          # Opens browser for OAuth2, stores credentials locally
sweatstack login --force  # Force re-authentication
sweatstack logout         # Remove stored credentials
sweatstack status         # Show auth status, user info, and version
```

Always `sweatstack status` to check if the user is authenticated.

## Project Configuration

Both `sweatstack app create` and `sweatstack app link` generate a `sweatstack.toml` in the current directory. Other commands read defaults from this file.

```toml
[app]
name = "My App"
client_id = "abc123"

[page]
slug = "my-page"
directory = "dist"
```

## Create Applications

```bash
sweatstack app create "My App" -d "Heart rate zone calculator" --page my-app --env
```

| Flag | Purpose |
|------|---------|
| `-d, --description` | App description (max 500 chars) |
| `-p, --page SLUG` | Associate with a SweatStack Page (auto-configures redirect URI) |
| `-s, --secret` | Generate client secret for confidential clients |
| `--env` | Write credentials to `.env` |
| `--env-file PATH` | Write credentials to specific file |
| `--json` | Output as JSON |

Creates a private application. Page slugs can be rejected if unavailable.

### Link Existing Application

```bash
sweatstack app link
```

Prompts to select from existing applications and creates `sweatstack.toml`. Use `--force` to overwrite an existing config.

## Deploy Static Sites

```bash
# With sweatstack.toml (recommended)
sweatstack page deploy

# Or specify explicitly
sweatstack page deploy my-page --dir ./dist
```

Uploads files to `https://{slug}.pages.sweatstack.dev`.

**Constraints:**
- Pages must be pre-created via dashboard: https://app.sweatstack.no/settings/api
- 10MB limit per app

### Publishing

Apps start as private. After deploy, the CLI prints a publish URL if the app is still private: `https://app.sweatstack.no/applications/{app_id}/publish`. Surface this URL to the user when they're ready to go live.

## Help

```bash
sweatstack --help
sweatstack <command> --help
```
