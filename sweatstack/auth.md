# OAuth2/OpenID Authentication

## Contents

- [Endpoints](#endpoints)
- [Scopes](#scopes)
- [PKCE Flow](#pkce-flow-public-clients)
- [Authorization Code Flow](#authorization-code-flow-private-clients)
- [Token Exchange](#token-exchange)
- [Refresh Tokens](#refresh-tokens)
- [API Authentication](#api-authentication)

---

## Endpoints

| Endpoint | URL |
|----------|-----|
| Authorization | `https://app.sweatstack.no/oauth/authorize` |
| Token | `https://app.sweatstack.no/api/v1/oauth/token` |

## Scopes

| Scope | Purpose |
|-------|---------|
| `openid` | OpenID Connect (currently unused by SweatStack) |
| `profile` | Access to profile information |
| `data:read` | Read access to user data |
| `data:write` | Write and delete access (no read) |
| `offline_access` | Refresh token for public clients |

**Default:** `openid profile data:read`

## PKCE Flow (Public Clients)

For browser apps, mobile apps, and other public clients without a client secret.

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

**Critical:** Include `prompt=none` to avoid double consent screens.

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

## Authorization Code Flow (Private Clients)

For server-side apps with a client secret.

### 1. Redirect to authorize

```
https://app.sweatstack.no/oauth/authorize?
  client_id=CLIENT_ID&
  redirect_uri=REDIRECT_URI&
  response_type=code&
  scope=openid%20profile%20data:read&
  prompt=none
```

### 2. Exchange code for token

```
POST https://app.sweatstack.no/api/v1/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&
code=AUTH_CODE&
redirect_uri=REDIRECT_URI&
client_id=CLIENT_ID&
client_secret=CLIENT_SECRET
```

## Token Exchange

**Response:**
```json
{
  "access_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "refresh_token": "...",
  "scope": "openid profile data:read"
}
```

- `refresh_token` included automatically for private clients
- Public clients must request `offline_access` scope

## Refresh Tokens

Exchange a refresh token for a new access token:

```
POST https://app.sweatstack.no/api/v1/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&
refresh_token=REFRESH_TOKEN&
client_id=CLIENT_ID
```

For private clients, include `client_secret`.

## API Authentication

All API requests require the Authorization header:

```
Authorization: Bearer ACCESS_TOKEN
```

## Token Lifecycle

- **Access token**: JWT, RS256, 15-minute TTL. Carries the standard `exp` claim. Decode it locally to know when to refresh; no network call needed. The token response also includes `expires_in` (seconds) for clients that prefer not to parse the JWT.
- **Refresh token**: no expiry until the user revokes the app's permissions. Apps used sporadically (a user opens once a month) refresh successfully without re-auth as long as the refresh token still works.

Treat `401` as "refresh and retry once", not "send the user back through OAuth".

## Redirect URIs

Registered redirect URIs accept both `http://` and `https://` schemes (validated as `AnyHttpUrl`). Pattern matching is prefix/suburl based.

- **HTTPS redirect URIs work directly** for native apps using iOS [Universal Links](https://developer.apple.com/ios/universal-links/) or Android [App Links](https://developer.android.com/training/app-links). No custom URL scheme is required, and **no relay or proxy is needed** to bounce a callback into the app.
- **Custom URL schemes** like `com.example.myapp://oauth/callback` also work. Simpler to set up; fine for v1.
- **`localhost`** is allowed even when no redirect URIs are configured on the application, to ease local development.
