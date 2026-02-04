# SweatStack API Reference

**Base URL:** `https://app.sweatstack.no`

**OpenAPI spec:** https://app.sweatstack.no/openapi.json

**Important:** Always fetch the OpenAPI spec to check request parameters and response schemas. Don't guess — the response structures are often more complex than expected.

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
| `/api/v1/longitudinal-data` | GET | Aggregate data (returns Parquet) |
| `/api/v1/longitudinal-mean-max` | GET | Historical mean-max (returns Parquet) |
| `/api/v1/oauth/userinfo` | GET | Current user info |

## Parquet Responses

Data endpoints return **Parquet files (snappy-compressed)**. Use DuckDB-WASM to parse in browser - it has full codec support including snappy.

### Setup (once at startup)

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

**Why DuckDB-WASM?** Other libraries (parquet-wasm, hyparquet) lack snappy codec support or have CDN issues. DuckDB-WASM is heavier (~10MB) but reliable.

## Metrics Parameter

Pass multiple times for multiple metrics:

```
?metrics=altitude&metrics=distance    ✓
?metrics=altitude,distance            ✗
```

## Available Metrics

duration, power, speed, heart_rate, cadence, altitude, temperature, core_temperature, smo2, distance, lactate, RPE

## Sports

**Formatting sport values for display:**

```python
parts = sport.split(".")
base = parts[0].replace("_", " ")
if len(parts) == 1:
    return base
rest = " ".join(parts[1:]).replace("_", " ")
return f"{base} ({rest})"
# "cycling.mountain" → "cycling (mountain)"
```

## Authentication

All endpoints require `Authorization: Bearer TOKEN` header.

See [webapp-guide.md](webapp-guide.md) for OAuth PKCE flow.
