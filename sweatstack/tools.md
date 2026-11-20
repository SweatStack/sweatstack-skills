# SweatStack Tools

Tools at `https://{slug}.sweatstack.tools` run entirely in the browser. One network policy, identical for every tool, keeps the person's data in their browser and within SweatStack. The browser enforces it: a request it blocks never leaves the page.

## Contents

- [What a Tool Can Reach](#what-a-tool-can-reach)
- [Rules](#rules)
- [Check Before Deploying](#check-before-deploying)
- [Fix a Blocked Load](#fix-a-blocked-load)
- [Maps](#maps)
- [Pyodide](#pyodide)
- [What Changes on the Server](#what-changes-on-the-server)

## What a Tool Can Reach

| Destination | How |
|---|---|
| The tool's own files | Any load, by relative path |
| `https://app.sweatstack.no` (the API) | `fetch` only |
| `https://maps.sweatstack.dev` (SweatStack Maps) | `fetch` only. MapLibre fetches styles, tiles and fonts this way |
| `http://localhost:*`, `http://127.0.0.1:*` | `fetch` only, after the browser asks. Safari blocks it |
| Bluetooth and USB devices | Chromium only, after the person picks a device |
| **Any other site** | **Blocked**: CDNs, Google Fonts, analytics, error tracking, third-party APIs and tile hosts |

A `<script>`, stylesheet, image or font from the API or Maps is blocked too. Only the tool's own files load.

## Rules

- **Ship every dependency in the tool.** Download each library into `vendor/` with the version in the file name (`vendor/uPlot.iife.min-1.6.31.js`) and load it by relative path. Keep licence files.
- **Bundle an ES module that imports packages by name** (`import ... from "apache-arrow"`): `npx esbuild <entry> --bundle --format=esm --outfile=vendor/<name>.mjs`.
- **DuckDB-WASM needs four files and one setting, including the Parquet extension.** Use the DuckDB-WASM setup in the API guide exactly. Without the extension, the first Parquet query fails with `NetworkError`.
- **Sign in with a redirect, never a popup.** A tool has no link to the window that opened it.
- **Don't use WebRTC.** `RTCPeerConnection` throws `NotSupportedError`.
- **Don't use speculation rules, `<link rel="preconnect">` or `<link rel="dns-prefetch">`.** SweatStack removes them.
- **Reach software on the person's computer only from a click,** not on page load: the browser asks first. Tell Safari users it won't work there.
- **Never call a third-party API.** If the tool needs one and uses SweatStack data, it is a connected app with its own hosting, not a tool.
- **Never send the person's data out:** not in a URL to `location.href` or `window.open`, not through a local helper program. It breaks the developer terms and the tool is taken down.

## Check Before Deploying

```bash
sweatstack tool check public/   # Lists every load from another site. Exit code 1 means fix them
sweatstack tool serve public/   # Serves locally under the production policy
```

Treat a non-zero exit from `tool check` as a failure to fix, not a warning. Then open the address `tool serve` prints and read the browser console: it shows what `tool check` can't see, URLs a library builds while it runs. Fix every Content Security Policy error before deploying. Both commands need SweatStack CLI 0.16.0 or later.

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
  const map = new maplibregl.Map({ container: 'map', style: 'https://maps.sweatstack.dev/v4/styles/light.json' });
</script>
```

- Styles: `light`, `dark`, `white`, `grayscale`, `black`.
- Keep the three `.mjs` files together: MapLibre finds its worker next to its module.
- Terrain: a `raster-dem` source with `url: 'https://maps.sweatstack.dev/terrain/v1.json'`.
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
- A tool's files work only on its own address. Other sites can't embed them.
- Limits: 50 MB per file, 99 MB and 20,000 files per tool.
