---
name: sweatstack
description: Builds applications integrating with SweatStack sports data platform. Provides OAuth PKCE authentication, API endpoints, and patterns for single-file HTML web apps. Use when building fitness dashboards, athletic data tools, or apps using SweatStack.
---

# SweatStack

Sports data platform providing auth, storage, and wearable integrations for developers.

**Base URL:** `https://app.sweatstack.no`

**Default scopes:** `openid profile activities:read offline_access`. Add a category only when the app uses it.

**Current docs:** https://docs.sweatstack.no/llms.txt lists every page as Markdown. When a guide here disagrees with the live API or docs, trust the live source.

## Reference

**Webapps:** Single-file HTML apps with vanilla JS. See [webapp.md](webapp.md)

**SweatStack Tools:** Tools at `{slug}.sweatstack.tools` that run entirely in the browser under a network lock: creating and deploying one with `sweatstack tool create` and `tool deploy`, what a tool can reach, sign-in (SweatStack Tools does it, never the tool), shipping dependencies, maps, and checking with `sweatstack tool serve` and `tool check`. Read before building or fixing a tool. See [tools.md](tools.md)

**CLI:** App management and deployment. See [cli.md](cli.md)

**Auth:** OAuth2/PKCE authentication. See [auth.md](auth.md)

**API:** Endpoints, data formats, and the attribution every app must show next to platform data. See [api.md](api.md)
