---
name: sweatstack
description: Builds applications integrating with SweatStack sports data platform. Provides OAuth PKCE authentication, API endpoints, and patterns for single-file HTML web apps. Use when building fitness dashboards, athletic data tools, or apps using SweatStack.
---

# SweatStack

Sports data platform providing auth, storage, and wearable integrations for developers.

**Base URL:** `https://app.sweatstack.no`

**Default scopes:** `openid profile data:read`

## Reference

**Webapps:** Default approach is single-file HTML with vanilla JS (no build step). See [webapp.md](webapp.md)

**CLI:** Create apps, deploy static sites, manage auth. See [cli.md](cli.md)

**Auth:** OAuth2/OpenID authentication. See [auth.md](auth.md)

**API:** Endpoints and data models. See [api.md](api.md)
