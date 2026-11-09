# SweatStack API Reference

## Contents

- [Common Gotchas](#common-gotchas)
- [Endpoints](#endpoints)
- [Choosing the Right Endpoint](#choosing-the-right-endpoint)
- [Data Fetching Patterns](#data-fetching-patterns)
- [Parquet Responses](#parquet-responses)
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
| `/api/v1/activities/longitudinal-mean-max` | GET | `activities:read` | Historical mean-max (returns Parquet) |
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

```javascript
import * as duckdb from 'https://cdn.jsdelivr.net/npm/@duckdb/duckdb-wasm@1.32.0/+esm';

const JSDELIVR_BUNDLES = duckdb.getJsDelivrBundles();
const bundle = await duckdb.selectBundle(JSDELIVR_BUNDLES);
const worker_url = URL.createObjectURL(
    new Blob([`importScripts("${bundle.mainWorker}");`], { type: 'text/javascript' })
);
const worker = new Worker(worker_url);
const logger = new duckdb.ConsoleLogger();
const db = new duckdb.AsyncDuckDB(logger, worker);
await db.instantiate(bundle.mainModule, bundle.pthreadWorker);
URL.revokeObjectURL(worker_url);
```

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

// Usage
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
