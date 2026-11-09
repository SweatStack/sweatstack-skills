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

---

## Tech Stack

- Single HTML file with inline `<style>` and `<script>`
- Vanilla JS only (no React, no build step)
- CDN dependencies when needed (e.g., html2canvas for sharing)
- localStorage for tokens and user preferences
- DuckDB-WASM for Parquet parsing (supports full SQL for analytics)

## Output Location

Place generated files in `public/index.html`. Creates a deployment-ready structure.

## Quality Bar

UI can be minimal - focus on functionality. Auth and API error handling must be solid: handle 401s, show clear error states, never fail silently.

## Prerequisites

Requires a **Client ID** from a SweatStack application.

**If `sweatstack.toml` exists:** Use its `client_id`, skip app creation.

**If user provides a client_id:** Use it directly, skip app creation.

**Otherwise, create an app with the SweatStack CLI:**
1. Derive app name from the task (e.g., "heart rate analyzer" → "Heart Rate Analyzer")
2. Generate page slug from app name: lowercase, spaces to hyphens (e.g., "heart-rate-analyzer")
3. Create the app and its page: `sweatstack app create "Heart Rate Analyzer" --page heart-rate-analyzer`. This registers the sign-in redirects and writes the `client_id` to `sweatstack.toml`.
4. If the slug is rejected (exit code `3`), prompt user for alternative

Prompt user for app name only if it cannot be reasonably inferred from the task.

## Authentication

Browser apps use the PKCE flow (public client, no client secret). SweatStack **is** the app's login: "Sign in with SweatStack" is the whole authentication, and for a first-time user it also creates their SweatStack account and starts backfilling their data. There is no separate signup to build.

**Scopes:** Request `openid profile activities:read offline_access` and add a category only when the app uses it; the auth guide lists them. Avoid `email` unless the app needs it: an app that requests it can't take the Pages fast track.

**Authorize requests:** Every sign-in uses the same authorize URL, with PKCE and `state`. Omit `prompt`: SweatStack sends a signed-in user who already granted straight back, and shows anyone else the sign-in or consent screen. A first-time user picks their wearable and onboards there.

**Token storage:** localStorage key `ss_tokens`, holding `access_token`, `expires_at` and `refresh_token`. Tabs share it, so only one tab refreshes at a time, under a Web Lock, and every refresh stores the new `refresh_token` from the response.

**On page load, in this order:**
1. Callback with `error`: clear the URL, show the error and the sign-in button. Never redirect from here, or a cancelled sign-in loops.
2. Callback with `code`: verify `state`, exchange the code, set the `ss_known` cookie, show the app.
3. Valid access token: show the app.
4. Refresh token: refresh, then show the app. On `invalid_grant`, clear the tokens and continue. On a network error, show it and keep the tokens.
5. `ss_known` cookie: redirect to authorize.
6. Otherwise: show the sign-in button.

**During use:** Refresh shortly before the access token expires. On `401`, refresh and retry once. If the refresh is refused with `invalid_grant`, clear the tokens and show the sign-in button.

**Returning user cookie:** `ss_known` sends a returning user without a usable token to authorize instead of the sign-in button, so they get back in without extra clicks. Sign-out deletes it. On `localhost`, and for the owner while the app isn't ready for others, a consent screen appears each time. That is expected.

### Auth Code

Use this as is; it implements everything above. Define `showApp()` and `showSignIn(message)` for the two views. Wire the sign-in button to `startAuth` and the sign-out button to `signOut`, call `boot()` on load, and make every API call through `api(path)`.

```javascript
const CLIENT_ID = '...';
const REDIRECT_URI = location.origin + location.pathname; // Works for localhost and production
const SCOPE = 'openid profile activities:read offline_access';
const AUTH_URL = 'https://app.sweatstack.no/oauth/authorize';
const TOKEN_URL = 'https://app.sweatstack.no/api/v1/oauth/token';
const API_BASE = 'https://app.sweatstack.no/api/v1';

// Thrown when the sign-in is gone. Show the sign-in button.
class SignedOut extends Error {
    constructor(message = 'Please sign in again.') { super(message); }
}

function b64url(bytes) {
    return btoa(String.fromCharCode(...bytes))
        .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function loadTokens() {
    try { return JSON.parse(localStorage.getItem('ss_tokens')); } catch { return null; }
}
function saveTokens(response) {
    const tokens = {
        access_token: response.access_token,
        expires_at: Date.now() + response.expires_in * 1000,
        refresh_token: response.refresh_token,
    };
    localStorage.setItem('ss_tokens', JSON.stringify(tokens));
    return tokens;
}
function clearTokens() {
    localStorage.removeItem('ss_tokens');
}

async function tokenRequest(params) {
    const response = await fetch(TOKEN_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ client_id: CLIENT_ID, ...params }),
    });
    const body = await response.json().catch(() => ({}));
    if (response.ok) return body;
    if (body.error === 'invalid_grant') throw new SignedOut();
    throw new Error(body.error_description || body.error || `token request failed (${response.status})`);
}

// One tab refreshes at a time, and every refresh can return a new refresh token.
// `stale` is the access token the caller can't use: expired, or answered with a 401.
function refreshTokens(stale) {
    return navigator.locks.request('ss-token-refresh', async () => {
        const tokens = loadTokens();
        // Another tab may have refreshed while this one waited for the lock.
        if (tokens && tokens.access_token !== stale && tokens.expires_at - Date.now() > 60000) return tokens;
        if (!tokens?.refresh_token) { clearTokens(); throw new SignedOut(); }
        try {
            return saveTokens(await tokenRequest({ grant_type: 'refresh_token', refresh_token: tokens.refresh_token }));
        } catch (e) {
            if (e instanceof SignedOut) clearTokens();
            throw e;
        }
    });
}

async function accessToken() {
    const tokens = loadTokens();
    if (!tokens) throw new SignedOut();
    if (tokens.expires_at - Date.now() > 60000) return tokens.access_token;
    return (await refreshTokens(tokens.access_token)).access_token;
}

// Every API call goes through here: it refreshes and retries once on a 401.
async function api(path) {
    let token = await accessToken();
    let response = await fetch(API_BASE + path, { headers: { Authorization: `Bearer ${token}` } });
    if (response.status === 401) {
        token = (await refreshTokens(token)).access_token;
        response = await fetch(API_BASE + path, { headers: { Authorization: `Bearer ${token}` } });
    }
    if (response.status === 401) { clearTokens(); throw new SignedOut(); }
    if (!response.ok) throw new Error(`request failed (${response.status})`);
    return response;
}

async function startAuth() {
    const verifier = b64url(crypto.getRandomValues(new Uint8Array(32)));
    const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(verifier));
    const state = b64url(crypto.getRandomValues(new Uint8Array(16)));
    sessionStorage.setItem('ss_pkce', JSON.stringify({ verifier, state }));
    location.assign(`${AUTH_URL}?${new URLSearchParams({
        response_type: 'code', client_id: CLIENT_ID, redirect_uri: REDIRECT_URI, scope: SCOPE,
        state, code_challenge: b64url(new Uint8Array(digest)), code_challenge_method: 'S256',
    })}`);
}

function signOut() {
    clearTokens();
    document.cookie = 'ss_known=; path=/; max-age=0';
    showSignIn();
}

// The page-load order. Never redirect from a callback, or a cancelled sign-in loops.
async function boot() {
    const params = new URLSearchParams(location.search);
    if (params.has('code') || params.has('error')) {
        history.replaceState(null, '', location.pathname);
        const pkce = JSON.parse(sessionStorage.getItem('ss_pkce'));
        sessionStorage.removeItem('ss_pkce');
        const error = params.get('error');
        if (error) {
            return showSignIn(params.get('error_description')
                || (error === 'access_denied' ? 'Sign-in was cancelled.' : `Sign-in failed (${error}).`));
        }
        if (!pkce || params.get('state') !== pkce.state) {
            return showSignIn('Sign-in could not be verified. Please try again.');
        }
        try {
            saveTokens(await tokenRequest({
                grant_type: 'authorization_code', code: params.get('code'), code_verifier: pkce.verifier,
            }));
        } catch (e) {
            return showSignIn(e instanceof SignedOut ? 'Sign-in expired. Please try again.' : `Sign-in failed: ${e.message}`);
        }
        document.cookie = 'ss_known=1; path=/; max-age=2147483647; SameSite=Lax';
        return showApp();
    }
    if (loadTokens()) {
        try {
            await accessToken();
            return showApp();
        } catch (e) {
            // A network error keeps the tokens, so a reload tries again.
            if (!(e instanceof SignedOut)) return showSignIn(`Could not reach SweatStack: ${e.message}`);
        }
    }
    if (document.cookie.split('; ').includes('ss_known=1')) return startAuth();
    showSignIn();
}
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
- A subtitle under the button naming the accounts users recognize, since most don't know SweatStack yet. Example: "Use your Garmin, Wahoo or Intervals.icu account".

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

**Preview locally:** `sweatstack page serve`. It keeps running, so start it in the background or suggest the user run it. Open the printed `http://localhost:<port>` URL; `127.0.0.1` won't match the redirect URI.

**Next steps to mention:**
- **Deploy to the web:** `sweatstack page deploy`
- **Make available to other users:** The app starts private. `deploy` prints what is still missing and a link to the app's Consent screen, where it goes live: `https://app.sweatstack.no/applications/{APP_ID}/consent`. A browser-only Pages app can tick the Pages fast track there, which fills in most of it.
