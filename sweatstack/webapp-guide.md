# Building Single-File Web Apps

## Tech Stack

- Single HTML file with inline `<style>` and `<script>`
- Vanilla JS only (no React, no build step)
- CDN dependencies when needed (e.g., html2canvas for sharing)
- sessionStorage for access token
- localStorage for user preferences

## Quality Bar

UI can be minimal - focus on functionality. Auth and API error handling must be solid: handle 401s, show clear error states, never fail silently.

## Prerequisites

Create a SweatStack application at https://app.sweatstack.no/applications/new

Required fields: Name, Description, URL, Image URL, Redirect URIs (HTTPS), Privacy Policy URL

Save to get your **Client ID**.

## OAuth 2.0 PKCE Flow

### 1. Generate PKCE pair

- Code verifier: random string (43-128 chars)
- Code challenge: base64url(SHA-256(verifier))

### 2. Redirect to authorize

```
https://app.sweatstack.no/oauth/authorize?
  client_id=CLIENT_ID&
  redirect_uri=REDIRECT_URI&
  response_type=code&
  scope=openid%20profile%20data:read&
  code_challenge=CHALLENGE&
  code_challenge_method=S256&
  prompt=none
```

**Critical:** Always include `prompt=none` to avoid double consent screens.

### 3. Exchange code for token

```
POST https://app.sweatstack.no/api/v1/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
code=AUTH_CODE&
redirect_uri=REDIRECT_URI&
client_id=CLIENT_ID&
code_verifier=VERIFIER
```

Response: `{ access_token, token_type, expires_in }`

### 4. Use token

Store in sessionStorage. Use as `Authorization: Bearer TOKEN` header.

### 5. Token lifecycle

Ignore refresh tokens in client-side apps. Store access token and `expires_in` in sessionStorage. When token expires or API returns 401, silently redirect to authorization flow with `prompt=none` to get a new token. User won't see consent screen again.

## HTML Structure

- Auth container (login button): shown when no token
- App container (main UI): shown after authentication
- Define constants: CLIENT_ID, REDIRECT_URI, AUTH_URL, TOKEN_URL, API_BASE

## Default Styling

Use only when user doesn't specify styling preferences.

**Scientific paper aesthetic:** Single centered column at comfortable reading width. Clear heading hierarchy. Generous whitespace. Light background, dark text. Everything flows vertically - no sidebars, no cards, no visual clutter. Think academic paper or long-form article, not a dashboard.

## SweatStack Branding

**Login button** (Norwegian flag red):

```html
<button onclick="startAuth()" style="
    background: #BA0C2F;
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
    Built with <a href="https://sweatstack.no/skills" style="color: #666;">SweatStack Skills</a>
</footer>
```

## Deployment

```bash
npx wrangler pages deploy .
```

## Reference Apps

- **graph.sweatstack.no** - Activity contribution graph
- **zones.sweatstack.no** - Training zone calculator
