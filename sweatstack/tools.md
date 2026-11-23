# SweatStack Tools

Tools at `https://{slug}.sweatstack.tools` run entirely in the browser. One network policy, identical for every tool, keeps the person's data in their browser and within SweatStack. The browser enforces it: a request it blocks never leaves the page.

## Contents

- [Create and Deploy](#create-and-deploy)
- [What a Tool Can Reach](#what-a-tool-can-reach)
- [Sign-in](#sign-in)
- [Rules](#rules)
- [Check Before Deploying](#check-before-deploying)
- [Fix a Blocked Load](#fix-a-blocked-load)
- [Maps](#maps)
- [Pyodide](#pyodide)
- [What Changes on the Server](#what-changes-on-the-server)

## Create and Deploy

```bash
sweatstack tool create --name power-duration --title "Power duration" \
  --description "Your best efforts over time." --scope activities:read
sweatstack tool serve        # Try it locally, signed in
sweatstack tool check public/
sweatstack tool deploy
```

- **`tool create`** creates a private tool at `https://{name}-{handle}.sweatstack.tools`, writes `sweatstack.toml`, and puts the template in `public/`: one page that signs in, loads the latest activity's Parquet with DuckDB-WASM and plots it. Build on the template rather than starting over.
- **Ask the person** for the name (lowercase words joined by hyphens), the title, and the data the tool needs, one `--scope` each (`activities:read` by default). The name can never change.
- **On their first tool,** pass their handle and public name with `--handle` and `--public-name`. The handle is in every tool's address and can never change, so always ask the person for it; never invent one.
- **`tool deploy`** checks the folder, uploads only changed files, and makes them live. Read the warnings it prints. A new tool is private: only its owner can open it.
- **`tool deploys`** lists the kept deploys; **`tool rollback [ID]`** serves one again.
- **Never run `tool publish`** unless the person asks: it opens the tool to everyone.
- **"This needs your passkey":** ask the person to run `sweatstack login`, then run the command again.

These commands need SweatStack CLI 0.17.0 or later.

## What a Tool Can Reach

| Destination | How |
|---|---|
| The tool's own files | Any load, by relative path |
| `https://app.sweatstack.no` (the API) | `fetch` only |
| `https://maps.sweatkraft.no` (SweatStack Maps) | `fetch` only. MapLibre fetches styles, tiles and fonts this way |
| `http://localhost:*`, `http://127.0.0.1:*` | `fetch` only, after the browser asks. Safari blocks it |
| Bluetooth and USB devices | Chromium only, after the person picks a device |
| **Any other site** | **Blocked**: CDNs, Google Fonts, analytics, error tracking, third-party APIs and tile hosts |

A `<script>`, stylesheet, image or font from the API or Maps is blocked too. Only the tool's own files load.

## Sign-in

**SweatStack Tools signs people in, not the tool. Never write OAuth code in a tool:** no `/oauth/authorize`, no PKCE, no client ID, no tokens in `localStorage`. Before a page of a tool that uses SweatStack data is served, SweatStack signs the person in. The tool reads the access token from a cookie and calls the API with it.

Copy this file into the tool as `vendor/sweatstack.js`, unchanged, and call the API only through `sweatstack(path, init)`. `sweatstack tool create` adds it:

```javascript
const COOKIE = /(?:^|; )__Host-sweatstack_access_token=([^;]*)/;
// Each Tools app pairs with one SweatStack app: staging tools with staging, the rest with production.
const API = location.hostname.endsWith(".sweatstack-tools-staging.dev")
  ? "https://staging.sweatstack.no"
  : "https://app.sweatstack.no";
let pending = null;

function cookieToken() {
  const match = document.cookie.match(COOKIE);
  return match ? match[1] : null;
}

function signIn() {
  const back = location.pathname + location.search;
  location.assign(`/_sweatstack/sign-in?return=${encodeURIComponent(back)}`);
}

function freshToken() {
  pending ??= fetch("/_sweatstack/token", { method: "POST" })
    .then(async (response) => {
      if (response.status === 401) {
        signIn();
        return new Promise(() => {}); // The page is going away.
      }
      if (!response.ok) throw new Error(`SweatStack sign-in failed: ${response.status}`);
      return (await response.json()).access_token;
    })
    .finally(() => { pending = null; });
  return pending;
}

export async function sweatstack(path, init = {}) {
  for (const retry of [false, true]) {
    const token = (!retry && cookieToken()) || (await freshToken());
    const headers = new Headers(init.headers);
    headers.set("Authorization", `Bearer ${token}`);
    const response = await fetch(`${API}${path}`, { ...init, headers });
    if (response.status !== 401 || retry) return response;
  }
}

export async function signOut() {
  await fetch("/_sweatstack/sign-out", { method: "POST" });
}
```

```javascript
import { sweatstack, signOut } from './vendor/sweatstack.js';

const response = await sweatstack('/api/v1/activities/latest');
const activity = await response.json();
```

- `sweatstack()` returns the `Response`. Check `response.ok` as with `fetch`.
- A request body must be a string, `Blob`, `FormData`, `ArrayBuffer` or `URLSearchParams`, never a stream: a request can be sent twice.
- **In a web worker,** there is no `document.cookie`: `POST /_sweatstack/token` returns `{access_token, expires_in}`. On `401`, post a message to the page, and the page navigates to `/_sweatstack/sign-in?return=` and its path.
- **Sign-out:** `await signOut()`, then show the tool's own signed-out state with a link to `/_sweatstack/sign-in?return=%2F`. Don't reload: a reload signs in again.
- There is no signed-out landing page. A tool that uses no SweatStack data declares no data scopes, and nobody signs in.

## Rules

- **Ship every dependency in the tool.** Download each library into `vendor/` with the version in the file name (`vendor/uPlot.iife.min-1.6.31.js`) and load it by relative path. Keep licence files.
- **Bundle an ES module that imports packages by name** (`import ... from "apache-arrow"`): `npx esbuild <entry> --bundle --format=esm --outfile=vendor/<name>.mjs`.
- **DuckDB-WASM needs four files and one setting, including the Parquet extension.** Use the DuckDB-WASM setup in the API guide exactly. Without the extension, the first Parquet query fails with `NetworkError`.
- **Never write OAuth code.** Use `vendor/sweatstack.js` ([Sign-in](#sign-in)).
- **Don't use WebRTC.** `RTCPeerConnection` throws `NotSupportedError`.
- **Don't use speculation rules, `<link rel="preconnect">` or `<link rel="dns-prefetch">`.** SweatStack removes them.
- **Reach software on the person's computer only from a click,** not on page load: the browser asks first. Tell Safari users it won't work there.
- **Never call a third-party API.** If the tool needs one and uses SweatStack data, it is a connected app with its own hosting, not a tool.
- **Show where the data comes from.** Put the API's attribution under the title of what the tool shows, as it is, and carry it into exports ([Attribution](api.md#attribution)). The template does this. SweatStack checks it, and a tool that drops it is taken down if it isn't fixed.
- **Never send the person's data out:** not in a URL to `location.href` or `window.open`, not through a local helper program. It breaks the developer terms and the tool is taken down.

## Check Before Deploying

```bash
sweatstack tool check public/   # Lists every load from another site. Exit code 1 means fix them
sweatstack tool serve           # Serves locally under the production policy, and signs in
```

`tool serve` reads `sweatstack.toml` (the tool's slug, folder and scopes) and signs in as SweatStack Tools does, at `http://{slug}.localhost:{port}`. Use Chrome or Firefox for it: Safari keeps no sign-in cookie on plain `http://`. Treat a non-zero exit from `tool check` as a failure to fix, not a warning. Then open the address `tool serve` prints and read the browser console: it shows what `tool check` can't see, URLs a library builds while it runs. Fix every Content Security Policy error before deploying.

## Fix a Blocked Load

The console names the URL and the kind of load:

```
Loading the script 'https://cdn.jsdelivr.net/npm/uplot@1.6.31/dist/uPlot.iife.min.js' violates the following Content Security Policy directive: "script-src 'self' ..."
```

Download that URL into `vendor/` and change the reference to the relative path. For a URL built at runtime (a library loading its own worker, WASM or extension), find the library's option for its base URL and point it at `vendor/`.

## Maps

Ship MapLibre GL JS and use a SweatStack Maps style:

```bash
npm install maplibre-gl@6.16.0
cp node_modules/maplibre-gl/dist/{maplibre-gl.mjs,maplibre-gl-shared.mjs,maplibre-gl-worker.mjs,maplibre-gl.css} public/vendor/
```

```html
<link rel="stylesheet" href="vendor/maplibre-gl.css">
<div id="map" style="height: 400px"></div>
<script type="module">
  import * as maplibregl from './vendor/maplibre-gl.mjs';
  const map = new maplibregl.Map({ container: 'map', style: 'https://maps.sweatkraft.no/v4/styles/light.json' });
</script>
```

- Styles: `light`, `dark`, `white`, `grayscale`, `black`.
- Keep the three `.mjs` files together: MapLibre finds its worker next to its module.
- Terrain: a `raster-dem` source with `url: 'https://maps.sweatkraft.no/terrain/v1.json'`.
- Keep MapLibre's attribution control: "© OpenStreetMap" must show on every map, and in every exported map image.

## Pyodide

Ship the release and point `indexURL` at it:

```bash
npm install pyodide@314.0.7
mkdir -p public/vendor/pyodide
cp node_modules/pyodide/{pyodide.mjs,pyodide.asm.mjs,pyodide.asm.wasm,python_stdlib.zip,pyodide-lock.json} public/vendor/pyodide/
```

```javascript
import { loadPyodide } from './vendor/pyodide/pyodide.mjs';
const pyodide = await loadPyodide({ indexURL: new URL('/vendor/pyodide/', location.origin).href });
```

Download the wheel of every package the code loads into `vendor/pyodide/`. `pyfetch` uses the browser's `fetch`, so it reaches the API and nothing else.

## What Changes on the Server

- Every HTML page gets a WebRTC block first in `<head>` and a small "Report" link. Leave room in a corner of the page.
- `_headers`, `_redirects` and `.htaccess` are served as plain files: a tool can't set headers.
- Paths starting with `_sweatstack` and `_gate` belong to SweatStack. A tool can't use them.
- A tool's files work only on its own address. Other sites can't embed them.
- Limits: 50 MB per file, 99 MB and 20,000 files per tool.
