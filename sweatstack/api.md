# SweatStack API Reference

## Contents

- [Common Gotchas](#common-gotchas)
- [Endpoints](#endpoints)
- [Choosing the Right Endpoint](#choosing-the-right-endpoint)
- [Data Fetching Patterns](#data-fetching-patterns)
- [Parquet Responses](#parquet-responses)
- [Mean-Max Across Activities](#mean-max-across-activities)
- [Attribution](#attribution)
- [Metrics Parameter](#metrics-parameter)
- [Available Metrics](#available-metrics)
- [GPS Data](#gps-data)
- [Sports](#sports)
- [Authentication](#authentication)

---

**Base URL:** `https://app.sweatstack.no`

**OpenAPI spec:** https://app.sweatstack.no/openapi.json

**IMPORTANT: Before making any API call, fetch the OpenAPI spec to verify:**
- Valid enum values (e.g. sports use hierarchical format like `walking.hiking`, not `hiking`)
- Required vs optional parameters
- Response schemas — look up the specific schema (e.g., `ActivitySummary`, `ActivityDetails`) before accessing fields
- Required scope — each operation's `security` lists it

Never guess field names or enum values. The spec is the source of truth.

## Common Gotchas

**Activity timestamps:** Use `start` / `end` (UTC) or `start_local` / `end_local` (user's local time). Not `start_time` or `started_at`.

**Key activity fields:** `id`, `sport`, `start`, `end`, `start_local`, `end_local`, `duration`, `metrics`, `tags`, `summary`, `laps`. Activities have no `name` or `description`.

**`duration`**: ISO 8601 string (`"PT46M14S"`), not a number of seconds.

**`metrics`**: Array of available data stream names (e.g. `["power", "heart_rate", "distance"]`). Use to check data availability without fetching activity data.

**`summary`**: Object with per-metric aggregates — `power.mean`, `power.max`, `heart_rate.mean`, `heart_rate.max`, `distance.sum`, `altitude.gain`, etc. A metric the activity did not record is absent or null.

**`laps`**: Always null on `/activities/`. Populated on `/activities/{id}` and `/activities/latest` when the recording had lap markers. Each lap has `start`, `end`, `duration`, and the per-metric fields directly (`lap.power.mean`).

**Nullable fields:** `summary`, `laps`, `traces`, `app_metadata` can be null. Always null-check before display.

**Date parameters:** Use `YYYY-MM-DD` format. Most endpoints reject timestamps.

**Sport filter:** The parameter is `sport`, repeated for several sports, on the activity list and the longitudinal endpoints alike.

**Timeseries columns:** Order and plot by `timestamp` (UTC) or `timestamp_local`. `duration` is how long a sample's values held, not the time since the start, so never use it as a time axis or sort key. Samples are usually 1 Hz but not guaranteed to be, so don't derive time from the row index. A requested metric the activity didn't record is a column of nulls.

**Empty results:** A new user's history is still backfilling, newest first. Render what's there instead of waiting. If a user has little or no data, `issue` on `/oauth/userinfo` says why (beta); show `issue.message` instead of an empty state.

## Endpoints

| Endpoint | Method | Scope | Purpose |
|----------|--------|-------|---------|
| `/api/v1/activities/` | GET | `activities:read` | List activities (filter: sport, tags, start, end) |
| `/api/v1/activities/{id}` | GET | `activities:read` | Get activity details |
| `/api/v1/activities/{id}/data` | GET | `activities:read` | Timeseries data (returns Parquet) |
| `/api/v1/activities/latest` | GET | `activities:read` | Most recent activity |
| `/api/v1/activities/upload` | POST | `activities:write` | Upload .fit or .csv files, optionally gzipped (max 10) |
| `/api/v1/profile/tags/` | GET | `activities:read` | User-defined tags |
| `/api/v1/profile/sports/` | GET | `activities:read` | Available sports hierarchy |
| `/api/v1/activities/longitudinal-data` | GET | `activities:read` | Timeseries data across activities. Allows extensive filtering on sports and metrics. (returns Parquet) |
| `/api/v1/activities/longitudinal-mean-max` | GET | `activities:read` | Best effort per duration across activities, such as a power-duration curve (returns Parquet). See [Mean-Max Across Activities](#mean-max-across-activities) |
| `/api/v1/dailies/{measure}` | GET | `wellness:read` | Daily measures. `menstrual_cycle_day` needs `reproductive_health:read`. |
| `/api/v1/oauth/userinfo` | GET | `openid` | Current user info. Name needs `profile`, email needs `email`. |

**Critical**: Never guess request parameters or body schemas. Use the openapi.json when not sure.

### Pagination on `/activities/`

`GET /api/v1/activities/` accepts `limit` (default 50, no hard cap), `offset` (default 0), and repeatable `sport` filters. Filter server-side instead of pulling 50 mixed activities and dropping ones you don't want client-side.

```
GET /api/v1/activities/?sport=cycling&sport=running.road&start=2026-04-20&limit=200&offset=0
```

Paginate by incrementing `offset` until the response is shorter than `limit`. For modest backfills (a few hundred activities), just raising `limit` to 500 in one request is also fine.

**Watermark pitfall:** if you're incrementally syncing into your own database, do not advance your "last synced" timestamp past activities you didn't fetch. Set the watermark to the `start` of the latest activity you *successfully processed*, not `Date.now()` at the moment the poll finished. Otherwise you'll permanently skip the tail of a paginated window on first install.

## Choosing the Right Endpoint

**Multi-activity analysis** (trends, distributions, comparisons): Use `/activities/longitudinal-data` — one request for all matching activities.

**Single activity** (detail view, route map): Use `/activities/{id}/data`.

## Data Fetching Patterns

**Time window comparisons:** Fetch the larger window once, filter client-side. Avoid multiple requests for overlapping or adjacent ranges.

**Bulk activity data:** Need data from many activities? Use `/activities/longitudinal-data` with filters instead of looping through `/activities/{id}/data` — one request vs N.

**Per-activity stats:** Longitudinal endpoints return raw samples with `activity_id`. Use DuckDB to aggregate: `GROUP BY activity_id`. They have no `lap` column; fetch an activity's own data for laps.

**Smaller payloads:** Add `segmentation_on=power` or `segmentation_on=speed` to the data endpoints for 20 to 50 times less data, with the mean-max curve and intensity distribution preserved. Each row is then one segment.

## Parquet Responses

Data endpoints return **Parquet files (ZSTD-compressed)**, although the OpenAPI spec labels the responses as JSON. Your Parquet library must support the ZSTD codec.

**Browser apps:** Use DuckDB-WASM (recommended - full SQL). For a lighter reader without SQL, use `hyparquet` with `hyparquet-compressors`.

**Other environments:** Any Parquet library with ZSTD support.

### DuckDB-WASM Setup (browser)

Ship DuckDB-WASM in the app's own `vendor/` folder. This works everywhere, and SweatStack Tools blocks loading it from a CDN. Four files, for version 1.32.0:

```bash
npm install @duckdb/duckdb-wasm@1.32.0
# The browser module imports apache-arrow by name: bundle it once.
npx esbuild node_modules/@duckdb/duckdb-wasm/dist/duckdb-browser.mjs --bundle --format=esm --outfile=public/vendor/duckdb.mjs
cp node_modules/@duckdb/duckdb-wasm/dist/{duckdb-eh.wasm,duckdb-browser-eh.worker.js} public/vendor/
# Parquet support is an extension. Without it, DuckDB fetches it from extensions.duckdb.org on the
# first Parquet query; SweatStack Tools blocks that and the query fails with NetworkError.
mkdir -p public/vendor/duckdb-extensions/v1.4.3/wasm_eh
curl -L -o public/vendor/duckdb-extensions/v1.4.3/wasm_eh/parquet.duckdb_extension.wasm \
  https://extensions.duckdb.org/v1.4.3/wasm_eh/parquet.duckdb_extension.wasm
```

```javascript
import * as duckdb from './vendor/duckdb.mjs';

// Absolute URLs: DuckDB's worker resolves relative ones against its own address.
const vendor = new URL('/vendor/', location.origin).href;
const db = new duckdb.AsyncDuckDB(new duckdb.VoidLogger(), new Worker(vendor + 'duckdb-browser-eh.worker.js'));
await db.instantiate(vendor + 'duckdb-eh.wasm');
const setup = await db.connect();
await setup.query(`SET custom_extension_repository = '${vendor}duckdb-extensions'`);
await setup.close();
```

`v1.4.3` is DuckDB's own version inside DuckDB-WASM 1.32.0. Keep the folder layout exactly.

### Parsing Parquet

```javascript
let fileCount = 0;

// `sql` reads the file as PARQUET. Reads values one by one: Arrow's toArray() loses nulls.
async function queryParquet(arrayBuffer, sql) {
    const name = `data-${fileCount++}.parquet`;
    await db.registerFileBuffer(name, new Uint8Array(arrayBuffer));
    const conn = await db.connect();
    try {
        const result = await conn.query(sql.replace(/PARQUET/g, `"${name}"`));
        const data = {};
        for (const field of result.schema.fields) {
            const column = result.getChild(field.name);
            data[field.name] = Array.from({ length: result.numRows }, (_, i) => {
                const value = column.get(i);
                return typeof value === 'bigint' ? Number(value) : value;
            });
        }
        return data;
    } finally {
        await conn.close();
        await db.dropFile(name);
    }
}

// Usage. In a SweatStack Tool, call sweatstack(path) instead of fetch: see tools.md
const response = await fetch(`${API_BASE}/activities/${id}/data?metrics=altitude&metrics=distance`, {
    headers: { 'Authorization': `Bearer ${token}` }
});
const data = await queryParquet(await response.arrayBuffer(), `
    SELECT EXTRACT(EPOCH FROM CAST(timestamp AS TIMESTAMP)) AS seconds,
           CAST(altitude AS DOUBLE) AS altitude,
           CAST(distance AS DOUBLE) AS distance
    FROM PARQUET ORDER BY timestamp
`);
// data = { seconds: [...], altitude: [...], distance: [...] }
```

Name the columns in the query and cast metrics to `DOUBLE`, so every value reaches JavaScript as a plain number or null.

**Note:** DuckDB-WASM is ~10MB.

## Mean-Max Across Activities

`GET /api/v1/activities/longitudinal-mean-max` returns the best value of one metric for each duration, over every matching activity: a power-duration curve in one request.

- **`metric`** (required): one metric, such as `power` or `speed`.
- **`sport`** (required, although the OpenAPI spec lists it as optional): repeat it for several, such as `sport=cycling&sport=running`. A sport includes its sub-sports: `cycling` matches `cycling.road` and `cycling+stationary`. Leaving it out is a `422`.
- **`start`**, **`end`**: `YYYY-MM-DD`. `end` defaults to today.
- **`durations`**: seconds, comma-separated (`5,60,300,1200`), or `all` for the full grid. Omit it for the default 19 durations.

One row per duration, ordered by duration:

| Column | Type | |
|---|---|---|
| `duration` | whole seconds | DuckDB reads it as a `BIGINT`; pyarrow and pandas as a duration |
| the metric, such as `power` | float | The best mean over that duration |
| `start` | timestamp, UTC | When that best effort started |
| `activity_id`, `sport` | string | The activity it came from |

No matching data is a `200` with zero rows and no `SweatStack-Attribution` header, not an error: show an empty state.

```sql
SELECT CAST(duration AS DOUBLE) AS seconds, CAST(power AS DOUBLE) AS power,
       epoch_ms(start) AS start_ms, activity_id, sport
FROM PARQUET ORDER BY seconds
```

## Attribution

Data from a platform such as Garmin must show where it came from, next to the data. SweatStack gives the wording: show it as it is, and never write "Garmin" yourself.

- **JSON records** (activities, dailies, sources, markers, max efforts): the `attribution` field, such as `"Garmin"`. `null` when nothing needs showing.
- **Parquet data** (`/activities/{id}/data`, `/activities/{id}/mean-max`, `/activities/longitudinal-data`, `/activities/longitudinal-mean-max`): the `SweatStack-Attribution` header, such as `Garmin` or `Data from Garmin and Strava`. Absent when nothing needs showing. Browsers can read it.

```javascript
// In a SweatStack Tool, call sweatstack(path) instead of fetch: see tools.md
const response = await fetch(`${API}/api/v1/activities/${id}/data?metrics=power`, { headers });
const attribution = response.headers.get('SweatStack-Attribution');  // null when none
sourceLine.textContent = attribution ?? '';
sourceLine.hidden = !attribution;
```

**Where to show it:**

- Next to the title or heading of what shows the data, visible without scrolling. Not in a footer, tooltip or collapsed section.
- A view of many records: each entry's own `attribution`, or one line for the view from the longitudinal header when the view is built from it.
- A chart drawn on a canvas: the line as text next to the chart.
- Exports carry it too: a CSV next to the data, a PDF on every page, and an image drawn into it.

## Metrics Parameter

Pass multiple times for multiple metrics:

```
?metrics=altitude&metrics=distance    ✓
?metrics=altitude,distance            ✗
```

## Available Metrics

duration, lap, power, speed, heart_rate, respiration_rate, smo2, core_temperature, elevation, altitude, cadence, temperature, distance, longitude, latitude, lactate, rpe, notes

Names are lowercase and case-sensitive. Units: `power` W, `speed` m/s, `distance` and `altitude` m, `heart_rate` bpm, `cadence` rpm or steps/min, temperatures °C, `smo2` %.

## GPS Data

Filter invalid coordinates:

```javascript
function isValidGPS(lat, lon) {
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) return false;
    if (lat < -90 || lat > 90) return false;
    if (lon < -180 || lon > 180) return false;

    const EPSILON = 1e-6;
    if (Math.abs(lat) < EPSILON && Math.abs(lon) < EPSILON) return false;

    return true;
}
```

Catches nulls, NaN, Null Island (0, 0), and garbage floats.

## Sports

Sports use the [Open Sport Taxonomy](https://open-sport-taxonomy.sweatstack.no): a dotted code from broad to specific, optionally followed by `+` modifiers (`cycling`, `cycling.road`, `cycling.road+stationary`, `running+race`). SweatStack normalizes every source-device sport into it. A label it doesn't recognize arrives as `sport: "generic"`. The source device's raw label string is **not preserved**.

Consequences:

- To detect a run regardless of subtype or modifier, check `sport.startsWith("running")`. Same pattern for cycling, swimming, etc.
- Treat `sport === "generic"` as "sport unknown". Useful for example when deciding whether to apply GPS smoothing assumptions.

**Formatting sport values for display:**

```javascript
function formatSport(sport) {
    const [code, ...modifiers] = sport.split("+");
    const [base, ...subtypes] = code.split(".");
    const details = [...subtypes, ...modifiers].join(", ");
    const label = details ? `${base} (${details})` : base;
    return label.replace(/_/g, " ");
}
// "cycling.mountain" → "cycling (mountain)"
// "cycling.road+stationary" → "cycling (road, stationary)"
```

## Authentication

All endpoints require `Authorization: Bearer TOKEN` header. A `403` names the scope the token lacks.
