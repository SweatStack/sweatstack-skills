# Building Single-File Web Apps

## Contents

- [Tech Stack](#tech-stack)
- [Quality Bar](#quality-bar)
- [Prerequisites](#prerequisites)
- [Authentication](#authentication)
- [HTML Structure](#html-structure)
- [Default Styling](#default-styling)
- [SweatStack Branding](#sweatstack-branding)
- [Deployment](#deployment)
- [Reference Apps](#reference-apps)

---

## Tech Stack

- Single HTML file with inline `<style>` and `<script>`
- Vanilla JS only (no React, no build step)
- CDN dependencies when needed (e.g., html2canvas for sharing)
- localStorage for access token and user preferences
- DuckDB-WASM for Parquet parsing (supports full SQL for analytics)

## Quality Bar

UI can be minimal - focus on functionality. Auth and API error handling must be solid: handle 401s, show clear error states, never fail silently.

## Prerequisites

Requires a **Client ID** from a SweatStack application.

**If user provides a client_id:** Use it directly, skip app creation.

**Otherwise, create an app with the SweatStack CLI:**
1. Derive app name from the task (e.g., "heart rate analyzer" → "Heart Rate Analyzer")
2. Generate page slug from app name: lowercase, spaces to hyphens (e.g., "heart-rate-analyzer")
3. Create the app with the sweatstack cli
4. If slug is rejected, prompt user for alternative

Prompt user for app name only if it cannot be reasonably inferred from the task.

## Authentication

Browser apps use PKCE flow (public client, no client secret).

**Critical:** Always include `prompt=none` in auth redirects to avoid double consent screens.

**Token storage:** Use localStorage. Store `access_token` and expiry timestamp.

**On page load:** No token → show login. Expired token → silent re-auth with `prompt=none`.

**On 401:** Silent re-auth with `prompt=none`.

**Constants to define:**
```javascript
const CLIENT_ID = '...';
const REDIRECT_URI = window.location.origin + window.location.pathname; // Works for localhost and production
const AUTH_URL = 'https://app.sweatstack.no/oauth/authorize';
const TOKEN_URL = 'https://app.sweatstack.no/api/v1/oauth/token';
const API_BASE = 'https://app.sweatstack.no/api/v1';
```

## HTML Structure

- Auth container (login button): shown when no token
- App container (main UI): shown after authentication

## Default Styling

Use only when user doesn't specify styling preferences.

**Aesthetic direction:** Minimal and clean. Think scientific paper, not dashboard.

**Layout:**
- Centered container, `max-width: 48rem`
- Visual elements fill container width
- Full-width only for apps that are primarily visual (e.g., mapping app)

**Styling:**
- Clear heading hierarchy with generous whitespace
- Light background, dark text
- Everything flows vertically — no sidebars, no cards, no visual clutter

**Typography:** System fonts are acceptable for minimal aesthetic. If choosing a web font, make it intentional — one distinctive font, not generic defaults like Inter or Roboto.

**What to avoid:** Generic "AI slop" — purple gradients, card-heavy layouts, excessive shadows, decorative elements that add no meaning. Minimalism requires precision in spacing and typography, not decoration.

## SweatStack Branding

**Login page content:**
- Brief explanation of what the app does
- Text explaining the app uses SweatStack to access sports data (e.g., "This app connects to SweatStack to access your workout data")

**Login button** (Norwegian flag red):

```html
<button onclick="startAuth()" style="
    background: #EF2B2D;
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    font-size: 1rem;
    border-radius: 4px;
    cursor: pointer;
">Connect with SweatStack</button>
```

**Logout button:** Top right of main content area (not viewport). Clears sessionStorage and returns to login view.

**Footer** (always present):

```html
<footer style="color: #666; font-size: 0.875rem; text-align: center; margin-top: 3rem;">
    Powered by <a href="https://sweatstack.no" style="color: #666;">SweatStack</a> ·
    Built with <a href="https://github.com/sweatStack/sweatstack-skills" style="color: #666;">Skills</a>
</footer>
```

## Deployment

```bash
npx wrangler pages deploy .
```

## Reference Apps

Study these for patterns:

- **graph.sweatstack.no** - Activity contribution graph
- **zones.sweatstack.no** - Training zone calculator
