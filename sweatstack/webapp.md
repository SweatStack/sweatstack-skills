# Building Single-File Web Apps

## Contents

- [Tech Stack](#tech-stack)
- [Output Location](#output-location)
- [Quality Bar](#quality-bar)
- [Prerequisites](#prerequisites)
- [Authentication](#authentication)
- [HTML Structure](#html-structure)
- [Default Styling](#default-styling)
- [SweatStack Branding](#sweatstack-branding)
- [After Generation](#after-generation)
- [Reference Apps](#reference-apps)

---

## Tech Stack

- Single HTML file with inline `<style>` and `<script>`
- Vanilla JS only (no React, no build step)
- CDN dependencies when needed (e.g., html2canvas for sharing)
- localStorage for access token and user preferences
- DuckDB-WASM for Parquet parsing (supports full SQL for analytics)

## Output Location

Place generated files in `public/index.html`. Creates a deployment-ready structure.

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

Browser apps use the PKCE flow (public client, no client secret). SweatStack **is** the app's login: "Sign in with SweatStack" is the whole authentication, and for a first-time user it also creates their SweatStack account and starts backfilling their data. There is no separate signup to build.

**Token storage:** Use localStorage. Store `access_token` and its expiry timestamp.

**Three auth moments, and they must not all use `prompt=none`:**

1. **Explicit sign-in** (user clicks "Sign in with SweatStack"): interactive authorize, **no `prompt=none`**. A first-time user has no SweatStack session yet; they must reach the sign-in screen to pick their wearable and onboard. `prompt=none` here comes back with `error=login_required` instead.
2. **Returning-user silent check** (page load, `ss_known` cookie set, no valid token): authorize **with `prompt=none`**. If the callback returns `error=login_required` / `interaction_required`, fall back to showing the sign-in button.
3. **Expired token** (`401`): silent re-auth **with `prompt=none`**. On the same error, fall back to the sign-in button.

`prompt=none` exists to spare returning users a redundant consent screen, not to power the first sign-in.

**On page load:**
- valid token → show the app
- no token + `ss_known` cookie → silent `prompt=none`; success → app, `login_required` → show the sign-in button
- no token + no cookie → show the sign-in button

### Returning User Cookie

On successful token exchange (OAuth callback), set a non-expiring cookie:

```javascript
document.cookie = "ss_known=1; path=/; max-age=2147483647; SameSite=Lax";
```

On page load, if this cookie is set but no valid token exists, skip the sign-in button and redirect straight to auth. The auth server session handles the rest, so returning users authenticate without extra clicks.

On logout, delete the cookie:

```javascript
document.cookie = "ss_known=; path=/; max-age=0";
```

**Constants to define:**
```javascript
const CLIENT_ID = '...';
const REDIRECT_URI = window.location.origin + window.location.pathname; // Works for localhost and production
const AUTH_URL = 'https://app.sweatstack.no/oauth/authorize';
const TOKEN_URL = 'https://app.sweatstack.no/api/v1/oauth/token';
const API_BASE = 'https://app.sweatstack.no/api/v1';
```

## HTML Structure

- Auth container (sign-in button): shown when no token
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

**Sign-in view content:**
- A brief line on what the app does.
- One line making clear SweatStack is the sign-in, and that the user's profile and workout history come with it. Example: "Sign in with SweatStack to bring your profile and workout history into this app. No separate signup."

**Sign-in button** (Norwegian flag red, `#EF2B2D`):

Canonical label is **"Sign in with SweatStack"**: it reads as identity, the way "Sign in with Google" does, and it is the whole login for this app. Give it a real class so it has hover and keyboard-focus states; an identity button with no affordance is a tell. Always set `type="button"` so it never submits a surrounding form.

```html
<style>
  .ss-signin {
    display: inline-flex; align-items: center; gap: 0.5rem;
    background: #EF2B2D; color: #fff; font: inherit; font-weight: 600;
    border: none; border-radius: 6px; padding: 0.75rem 1.5rem; cursor: pointer;
    transition: filter 0.15s ease;
  }
  .ss-signin:hover { filter: brightness(0.93); }
  .ss-signin:focus-visible { outline: 2px solid #EF2B2D; outline-offset: 2px; }
</style>

<button type="button" class="ss-signin" onclick="startAuth()">Sign in with SweatStack</button>
```

**Sign-out button:** Top right of main content area (not viewport). Clears stored tokens, deletes the `ss_known` cookie, and returns to the sign-in view.

**Footer** (always present):

```html
<footer style="color: #666; font-size: 0.875rem; text-align: center; margin-top: 3rem;">
    Powered by <a href="https://sweatstack.no" style="color: #666;">SweatStack</a> ·
    Built with <a href="https://github.com/sweatstack/sweatstack-skills" style="color: #666;">Skills</a>
</footer>
```

## After Generation

**Preview locally:** Suggest user start a local file server in the `public/` directory.

**Next steps to mention:**
- **Deploy to the web:** `sweatstack page deploy <slug> ./public`
- **Make available to other users:** Add privacy policy and app description at `https://app.sweatstack.no/applications/{APP_ID}`

## Reference Apps

Study these for patterns:

- **graph.sweatstack.no** - Activity contribution graph
- **zones.sweatstack.no** - Training zone calculator
