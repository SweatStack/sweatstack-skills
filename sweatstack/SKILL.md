---
name: sweatstack
description: Builds applications integrating with SweatStack sports data platform. Provides OAuth PKCE authentication, API endpoints, and patterns for single-file HTML web apps. Use when building fitness dashboards, athletic data tools, or apps using SweatStack.
---

# SweatStack

Sports data platform providing auth, storage, and wearable integrations for developers.

**Base URL:** `https://app.sweatstack.no`

**Default scopes:** `openid profile data:read`

**For refresh tokens in public apps:** Add `offline_access` scope (private apps get refresh tokens automatically)

## Guides

**Building a single-file webapp?** See [webapp-guide.md](webapp-guide.md)

**CLI available** for creating apps, deploying static sites, and managing auth. See [cli-guide.md](cli-guide.md)

## Reference

**API endpoints and data models:** See [api.md](api.md)
