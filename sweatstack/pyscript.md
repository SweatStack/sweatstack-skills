# PyScript Web Apps

Use when the user needs Python data science libraries (pandas, numpy, scikit-learn, scipy, matplotlib) in the browser. No backend — static deployment.

## Trade-offs vs Vanilla JS Webapp

| | PyScript | Vanilla JS ([webapp.md](webapp.md)) |
|---|---|---|
| **Best for** | Data analysis, ML, statistical computing | Dashboards, visualizations, simple data display |
| **Libraries** | Full Python ecosystem via Pyodide | Browser JS only |
| **Cold start** | 10-20s (loading Pyodide + packages) | Instant |
| **Computation** | Client-side Python (slower than native) | Client-side JS (fast) |

Confirm with user before choosing PyScript — the cold start is significant.

## Template

**Repo:** https://github.com/sweatstack/sweatstack-pyscript-template

Clone the template to start. The README covers setup, the ctx API, parameter patterns, examples, and deployment.

## Workflow

1. Clone the template repo
2. Register an OAuth app with `sweatstack auth register`
3. Set Client ID in `index.html`
4. Write analysis logic in `main.py`
5. Deploy with `sweatstack apps deploy`

## Key Constraints

- **Only edit `main.py` and `index.html`.** Do not generate or modify `app.js`, `worker.py`, `runtime.py`, CSS, or `mini-coi.js` — these are framework files maintained by the template.
- The template includes 4 working examples (`examples/`) — use these as reference for different patterns (single activity, multi-parameter, ML pipelines).

## Pyodide Gotchas

- **Duration column**: Has unreliable dtype across environments. Do not use as a numeric time axis. Sort by `duration` for ordering, then use `np.arange(len(df))` for seconds-from-start (data is 1-second sampled).
- **Large datasets**: Longitudinal data spanning months can be 100k+ rows. Downsample for ML training to keep browser-side computation fast (~80k rows max for sklearn).
