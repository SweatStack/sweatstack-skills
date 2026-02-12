# SweatStack API Reference

## Contents

- [Endpoints](#endpoints)
- [Choosing the Right Endpoint](#choosing-the-right-endpoint)
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
- Response schemas — look up the specific schema (e.g., `ActivityRead`) before accessing fields

Never guess field names or enum values. The spec is the source of truth.

## Common Gotchas

**Activity timestamps:** Use `start` (UTC) or `start_local` (user's local time). Not `start_time`, `started_at`, or `timestamp`.

**Key activity fields:** `id`, `start`, `start_local`, `sport`, `duration`, `name`, `description`

**Date parameters:** Use `YYYY-MM-DD` format. Most endpoints reject timestamps.

## Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/activities/` | GET | List activities (filter: sport, tags, start, end) |
| `/api/v1/activities/{id}` | GET | Get activity details |
| `/api/v1/activities/{id}/data` | GET | Timeseries data (returns Parquet) |
| `/api/v1/activities/latest` | GET | Most recent activity |
| `/api/v1/activities/upload` | POST | Upload .fit files (max 10) |
| `/api/v1/profile/metabolic-map` | GET | Zone thresholds (returns Parquet) |
| `/api/v1/profile/tags/` | GET | User-defined tags |
| `/api/v1/profile/sports/` | GET | Available sports hierarchy |
| `/api/v1/longitudinal-data` | GET | Timeseries data across activities. Allows extensive filtering on sports and metrics. (returns Parquet) |
| `/api/v1/longitudinal-mean-max` | GET | Historical mean-max (returns Parquet) |
| `/api/v1/oauth/userinfo` | GET | Current user info |

**Critical**: Never guess request paramaters or body schemas. Use the openapi.json when not sure.

## Choosing the Right Endpoint

**Multi-activity analysis** (trends, distributions, comparisons): Use `/longitudinal-data` — one request for all matching activities.

**Single activity** (detail view, route map): Use `/activities/{id}/data`.

## Parquet Responses

Data endpoints return **Parquet files (snappy-compressed)**. Your Parquet library must support snappy codec.

**Browser apps:** Use DuckDB-WASM (recommended - full codec support, reliable CDN).

**Other environments:** Any Parquet library with snappy support.

### DuckDB-WASM Setup (browser)

```javascript
import * as duckdb from 'https://cdn.jsdelivr.net/npm/@duckdb/duckdb-wasm@1.28.0/+esm';

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
async function parseParquet(arrayBuffer) {
    const uint8 = new Uint8Array(arrayBuffer);
    await db.registerFileBuffer('data.parquet', uint8);
    const conn = await db.connect();
    const result = await conn.query('SELECT * FROM "data.parquet"');

    const data = {};
    for (const field of result.schema.fields) {
        data[field.name] = result.getChild(field.name).toArray();
    }
    await conn.close();
    return data;
}

// Usage
const response = await fetch(`${API_BASE}/activities/${id}/data?metrics=altitude&metrics=distance`, {
    headers: { 'Authorization': `Bearer ${token}` }
});
const data = await parseParquet(await response.arrayBuffer());
// data = { altitude: [...], distance: [...] }
```

**Note:** DuckDB-WASM is ~10MB but reliable. Other browser libraries (parquet-wasm, hyparquet) have codec or CDN issues.

## Metrics Parameter

Pass multiple times for multiple metrics:

```
?metrics=altitude&metrics=distance    ✓
?metrics=altitude,distance            ✗
```

## Available Metrics

duration, power, speed, heart_rate, cadence, altitude, latitude, longitude, temperature, core_temperature, smo2, distance, lactate, RPE

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

Catches NaN (from null values), Null Island (0, 0), and garbage floats.

## Sports

**Formatting sport values for display:**

```javascript
function formatSport(sport) {
    const parts = sport.split(".");
    const base = parts[0].replace(/_/g, " ");
    if (parts.length === 1) return base;
    const rest = parts.slice(1).join(" ").replace(/_/g, " ");
    return `${base} (${rest})`;
}
// "cycling.mountain" → "cycling (mountain)"
```

## Authentication

All endpoints require `Authorization: Bearer TOKEN` header.
