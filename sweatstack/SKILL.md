---
name: sweatstack
description: Builds applications integrating with SweatStack sports data platform. Provides OAuth PKCE authentication, API endpoints, and patterns for single-file HTML web apps. Use when building fitness dashboards, athletic data tools, or apps using SweatStack.
---

# SweatStack

Sports data platform providing auth, storage, and wearable integrations for developers.

**Base URL:** `https://app.sweatstack.no`

**Default scopes:** `openid profile data:read`

## Guides

**Webapps:** Default approach is single-file HTML with vanilla JS (no build step). See [webapp.md](webapp.md)

**CLI available** for creating apps, deploying static sites, and managing auth. See [cli.md](cli.md)

## Reference

**OAuth2/OpenID authentication:** See [auth.md](auth.md)

**API endpoints and data models:** See [api.md](api.md)
