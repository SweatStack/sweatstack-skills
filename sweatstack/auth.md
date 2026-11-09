# OAuth2/OpenID Authentication

## Contents

- [Endpoints](#endpoints)
- [Scopes](#scopes)
- [Authorization Request](#authorization-request)
- [PKCE Flow](#pkce-flow-public-clients)
- [Authorization Code Flow](#authorization-code-flow-private-clients)
- [Token Response](#token-response)
- [Refresh Tokens](#refresh-tokens)
- [API Authentication](#api-authentication)
- [Token Lifecycle](#token-lifecycle)
- [Redirect URIs](#redirect-uris)

---

## Endpoints

| Endpoint | URL |
|----------|-----|
| Authorization | `https://app.sweatstack.no/oauth/authorize` |
| Token | `https://app.sweatstack.no/api/v1/oauth/token` |
| OIDC discovery | `https://app.sweatstack.no/.well-known/openid-configuration` |
| JWKS | `https://app.sweatstack.no/.well-known/jwks.json` |

## Scopes

**Start with `openid profile activities:read offline_access`**, what a new app requests by default. Add a category only when the app uses it: each one is a line on the user's consent screen.

| Scope | Grants |
|-------|--------|
| `openid` | `sub` on userinfo and the ID token |
| `profile` | The name claims |
| `email` | `email` on userinfo (never in the ID token) |
| `offline_access` | A refresh token for PKCE clients. Client-secret clients always get one. |
| `activities:read`, `activities:write` | Activities, tests, traces and training analysis, including zones and the metabolic map under `/profile/` |
| `wellness:read`, `wellness:write` | Daily measures, except the menstrual cycle day |
| `reproductive_health:read`, `reproductive_health:write` | The menstrual cycle day. Standalone. |
| `workouts:read`, `workouts:write` | Scheduled workouts. Write sends them to the user's devices. |
| `sharing:read`, `sharing:write` | Who shares with the user, delegated tokens, managed accounts |

- **Write does not grant read.** Request both verbs if the app does both.
- **A `403` names the missing scope.** Each operation's `security` in the OpenAPI spec lists its scope.
- **Never request `data:read` or `data:write`, even if existing code does.** They are retired bundles: a new app gets `invalid_scope` for them. To migrate an older app, follow the box on its Overview tab, because a category without a purpose turns users away.
- **Purposes:** every category except `openid`, `profile` and `offline_access` needs a purpose before anyone but the owner can connect. Tick the category under "Data your app uses" on the app's Consent screen tab and write its purpose there. Without one, other users are refused and return with `error=access_denied`.
- **Consent only grows.** The grant is the union of everything the user approved. Requesting fewer scopes later removes nothing.

## Authorization Request

Both flows start with the same URL; PKCE adds its two parameters.

```
https://app.sweatstack.no/oauth/authorize?
  client_id=CLIENT_ID&
  redirect_uri=REDIRECT_URI&
  response_type=code&
  scope=openid%20profile%20activities:read%20offline_access&
  state=STATE
```

**Omit `prompt`.** SweatStack decides: a signed-in user who already granted these scopes goes straight back with a code; anyone else gets the sign-in or consent screen. No other parameter is needed to skip consent.

**Never use `prompt=none`.** It skips nothing extra and is not a silent check: SweatStack currently shows a screen instead of returning `login_required` or `consent_required`, and this fallback is deprecated in favor of those errors. Code that sends it, or waits for those errors, is wrong either way.

Use `prompt=consent` only to force the consent screen; `login` and `select_account` behave the same way.

**Consent still appears for a user who granted:**
- on every loopback (`localhost`) redirect
- for the owner on their own app, while anyone else would be refused the request; the screen says what to fix

**The callback** carries `code` and `state`, or `error` and `state`. Verify `state`, and handle `error` (`access_denied` when the user cancels or is refused) by showing it to the user.

**Optional parameters:**

| Parameter | Effect |
|-----------|--------|
| `email_auth_mode=existing_only` | Steers new users to a wearable sign-in. Wording only, not enforced. Use when the app needs activity data from day one. |
| `integration` | Skips the sign-in chooser and goes straight to one provider: `intervals_icu`, `wahoo`, or `garmin_connect` (Pages apps only). The user must be told they connect through SweatStack. |
| `login_hint` | Prefills the email field |

## PKCE Flow (Public Clients)

For browser apps, mobile apps, and other public clients without a client secret.

### 1. Generate PKCE pair

- Code verifier: random string (43-128 chars)
- Code challenge: base64url(SHA-256(verifier))

### 2. Redirect to authorize

Add `code_challenge=CHALLENGE&code_challenge_method=S256` to the [authorization URL](#authorization-request).

### 3. Exchange code for token

```
POST https://app.sweatstack.no/api/v1/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
code=AUTH_CODE&
client_id=CLIENT_ID&
code_verifier=VERIFIER
```

## Authorization Code Flow (Private Clients)

For server-side apps with a client secret.

### 1. Redirect to authorize

Use the [authorization URL](#authorization-request) as is.

### 2. Exchange code for token

```
POST https://app.sweatstack.no/api/v1/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
code=AUTH_CODE&
client_id=CLIENT_ID&
client_secret=CLIENT_SECRET
```

## Token Response

```json
{
  "access_token": "...",
  "token_type": "Bearer",
  "expires_in": 900,
  "refresh_token": "...",
  "scope": "openid profile activities:read offline_access",
  "id_token": "..."
}
```

- An empty `refresh_token` on a PKCE client means the request lacked `offline_access`.
- Read granted scopes from `scope`. Decoded, the JWT carries them in a `scopes` array instead.

## Refresh Tokens

Exchange a refresh token for a new access token:

```
POST https://app.sweatstack.no/api/v1/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&
refresh_token=REFRESH_TOKEN&
client_id=CLIENT_ID
```

For private clients, include `client_secret`. The response has the same shape as the first token response.

- **Keep the `refresh_token` from every response** and send that one next time. It can differ from the one you sent, and then the old one may stop working.
- **One holder per refresh token.** Only one process or tab refreshes at a time and shares the result. A browser app serializes refreshes across tabs with the Web Locks API.

## API Authentication

All API requests require the Authorization header:

```
Authorization: Bearer ACCESS_TOKEN
```

## Token Lifecycle

- **Access token**: JWT, RS256, 15-minute TTL. Carries the standard `exp` claim. Decode it locally to know when to refresh; no network call needed. The token response also includes `expires_in` (seconds) for clients that prefer not to parse the JWT.
- **Refresh token**: valid until the user revokes the app's permissions, or until 365 days pass unused. Each use restarts the year, so apps used sporadically (a user opens once a month) refresh without re-auth.

Treat `401` as "refresh and retry once", not "send the user back through OAuth". Send the user through authorization again only when the refresh is refused with `invalid_grant`.

## Redirect URIs

Registered redirect URIs follow RFC 8252: `https://`, plain `http://` only for loopback hosts (`localhost`, `127.0.0.1`, `::1`), and custom schemes. `http(s)` URIs match by prefix (a registered URI also allows its sub-paths) and, when registered without a port, any port. Custom schemes must match exactly.

- **HTTPS redirect URIs work directly** for native apps using iOS [Universal Links](https://developer.apple.com/ios/universal-links/) or Android [App Links](https://developer.android.com/training/app-links). No custom URL scheme is required, and **no relay or proxy is needed** to bounce a callback into the app.
- **Custom URL schemes** like `com.example.myapp://oauth/callback` also work. Simpler to set up; fine for v1.
- **Loopback hosts** (`localhost`, `127.0.0.1`, `::1`) are allowed on any port while no redirect URIs are configured, to ease local development. Once any redirect URI is set, only registered URIs work, so add `http://localhost` explicitly if local development should keep working.
