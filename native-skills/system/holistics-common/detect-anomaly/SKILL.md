---
name: detect-anomaly
label: Detect anomaly
description: |-
  Detect statistical anomalies across a metric's history and visualize them — unusual spikes, drops, and deviations flagged against an expected range built from the metric's own recent history.

  Use when the user wants to find or check for unusual values in a metric — words like anomaly, unusual, spike, drop, dip, outlier, "out of the ordinary", "anything weird". A specific date is optional; the skill always scans the whole series.

  Typical phrasings: detect anomalies in revenue, any outliers in daily signups, has anything looked unusual in MRR lately, were there spikes or drops in active users this quarter, is revenue on May 20 unusual (a focus date — still scans the full series), or /detect_anomaly with no args (the skill asks for the metric).

  Do NOT trigger for: dimensional attribution (which segment or dimension drove an anomaly), explaining the business cause, or ongoing/scheduled monitoring & alerting. This skill flags which points are statistically unusual and shows them; it does not explain why.
---

Find which values in a metric are statistically unusual given the metric's own recent history, and show them: build an expected range from recent history, flag the points outside it, and visualize the result. This skill flags *which* points are unusual, never *why* — deflect causal or dimensional-attribution asks (Conventions → *Edge cases*).

## What a good input looks like
An anomaly task scans one metric's full history against an expected range built from its own past. It's fully specified once you can answer the fields below. Only `metric` is required — derive or default the rest, then echo everything back, including the resolved timeframe as an absolute date range (e.g. *"Aug 19, 2025 – May 29, 2026"*), so the user can correct a mis-parse.

| Field | Required | Examples | If missing |
|---|---|---|---|
| `metric` | **Yes** | `revenue`, `signups`, `MRR`, `daily_active_users` | Ask the user; don't guess. |
| `focus_date` | No | `May 20`, `last Tuesday`, `2026-05-20` | Optional. Changes only the closing prose (Step 5), never the detection or chart. |
| `granularity` | Inferred | `day`, `week`, `month`, `quarter` | Derive from the metric's time dimension and any date phrasing. If ambiguous, ask. |
| `filters` | No | `Region=West`, `Plan=Pro` | Optional. If present, fold into the Step 3 query. |
| `timeframe` | No | `last 90 days`, `last 6 months`, `this quarter` | Optional. Default by granularity: `day` → 90 days, `week` → 26 weeks, `month` → 24 months, `quarter` → 12 quarters. These are performance-first defaults, not business limits: use them unless the user asks for full history or the shorter range is insufficient for classification. |

## What a bare minimum output looks like
The deliverable is a combination chart plus a short prose summary — nothing else by default.
- **The combination chart** (Step 4): `actual` as a solid blue line, the `lower_bound`/`upper_bound` band dashed grey, and `is_anomaly` as red columns on a secondary 0..1 axis, with tooltips.
- **The prose summary** (Step 5): written for a business reader — defines an anomaly, then lists each flagged bucket (date, value, above/below the range, how far out in plain terms).
- **The anomaly results** (the Step 3 AQL) stay internal — the source of truth for the summary, not shown as a table unless the user asks for the raw numbers.
- If `execute_viz` ultimately fails, fall back to the Step 3 table + prose (Conventions → *On an error*).

## Workflow
Five steps, in order. You author the AML yourself from the templates in Schema — substitute the resolved dataset's real names, then `validate_aql` (AQL steps) and `execute_aql` / `execute_viz` to run. Don't call `generate_aql` / `generate_viz` (Conventions → *Write the AML yourself*).

Placeholders used throughout: `M` = the metric measure (e.g. `mou_monthly_mrr.sum_total_mrr`), `T` = the bound time dimension, `W` = the window for the granularity, `<dataset>` = the dataset name, `<metric label>` = a readable label.

### Step 1 — Parse inputs
Parse the fields in *What a good input looks like* and echo them back (with the resolved timeframe as an absolute range). If `metric` is missing, ask. Derive `granularity` from the metric's time dimension and any date phrasing; if ambiguous, ask.

### Step 2 — Resolve the dataset
Anchor to one dataset per invocation:

1. If the user named a dataset → `fetch_dataset(dataset_uname=<name>)` and proceed.
2. Else: `list_datasets()`, rank candidates by how well the metric name matches each dataset's measures/labels/descriptions (prefer measure matches), `fetch_dataset` the top candidate, then confirm before proceeding (*"I'll use `sales_orders` (has measure `total_revenue`). Confirm, or name another."*). Wait for confirmation.
3. If `list_datasets()` errors (e.g. "not supported in development mode"), ask the user to name the dataset explicitly.

**Validate the metric.** Confirm `metric` exists as a measure. If not, show the top-3 closest measure names (with descriptions) and ask which to use.

**Bind the time axis.** Find the dataset's date/timestamp dimension. If multiple exist, prefer: (a) the one tagged primary in metadata; (b) the one most referenced by the metric's definition; (c) a dimension named `event_date`, `created_at`, `date`, or `timestamp` (in that order). If still ambiguous, ask. Resolve any relative `focus_date` in the dataset's stated timezone and echo the absolute date back.

### Step 3 — Anomaly query (write AQL → validate_aql → execute_aql)
Write the whole query in one go from Schema → *Anomaly query*, substituting `M`, `T`, `W` and folding in any filters/timeframe. Pick `W` and apply the short-series rules from Schema → *Method*.

`validate_aql`, then `execute_aql` (title per Conventions → *Titles*). The result is the **anomaly results** — the answer the summary reads from. In the first `W` buckets `z_score` is null so `is_anomaly` is `0`; use the null `z_score`, not the flag, to tell these from true non-anomalies.

### Step 4 — Build the anomaly chart (write CombinationChart → execute_viz)
Write one self-contained `CombinationChart` from Schema → *Anomaly chart* and run it with `execute_viz` (title per Conventions → *Titles*). This chart — `actual` line, dashed expected-range band, red anomaly columns — is the final deliverable. On a render failure, follow Conventions → *On an error*.

### Step 5 — Summarize
Present the Step 4 chart plus the prose below — nothing else. Read the anomaly results to write it; don't render them as a table (the user sees the chart) unless asked.

Write for a business reader: plain and professional, no raw notation (no bare "σ", "z = 3.4", "3σ", or "k") — but standard terms (standard deviation, expected range) are welcome. Numbers per Conventions → *Numeric formatting*.

Open with one sentence defining an anomaly, then the findings. Lead sentence (fill `<k>` = threshold, `<W>`, `<granularity>`):

> *An anomaly is any <granularity> whose value falls more than <k> standard deviations from its expected level — outside the range built from the previous <W> <granularity>s (their average, plus or minus that range's width).*

Classify each bucket from the anomaly results:
- **Unusual** — `is_anomaly = 1`: above the expected range (`actual > rolling_mean`) or below it.
- **Normal** — `is_anomaly = 0` and `z_score` non-null: within the range.
- **Not enough history** — `z_score` null: one of the first `<W>` buckets, before a range exists (shown on the chart without a band).

Translate the statistics — don't print the raw fields:
- **z_score** → *"about <z> standard deviations from expected"*, only as a parenthetical, never the headline number.
- **k** → the flag threshold in standard deviations (default 3; see Method). Lower flags more (milder deviations); higher flags only extremes.

No focus date (primary path):

> **Found <N> unusual <granularity>(s) in <metric label>** over **<resolved timeframe>**:
> - **<date>** — <value>: **<above|below>** the expected range of <lower_bound>–<upper_bound> (about <z> standard deviations from expected).
> - … one bullet per flagged bucket, chronological

If `N = 0`: *"No unusual values in <metric label> over <resolved timeframe> — every value stayed within its expected range."*

Focus date given: lead with the verdict on that bucket, then the same list.
- Unusual: *"**<metric label> on <date> = <value>** is unusual — **<above|below>** the expected range of <lower_bound>–<upper_bound> (about <z> standard deviations from expected)."*
- Normal: *"**<metric label> on <date> = <value>** is within the expected range of <lower_bound>–<upper_bound> — not unusual."*
- `actual` null at that bucket: *"No data for <metric label> on <date> with filters <filters>."*
- Within the first `W` (no band): *"Not enough history to assess <date> — it's in the first <W> <granularity>s, before a range can be built; shown on the chart without a band."*

Then: *"Across the full <resolved timeframe>, found <N> unusual <granularity>(s):"* + the list.

Closing pointer (N ≥ 1): why an anomaly happened or which dimension drove it is out of scope — invite the user to investigate via a dimensional breakdown and business context (marketing calendar, CRM, recent news).

Post-run override (offer last): *"Want me to re-run with a stricter or looser threshold? Looser flags more <granularity>s (milder deviations); stricter flags only the most extreme. A seasonality-aware version (a curved expected line for weekly/annual patterns) is also available."* The threshold is `k` standard deviations (looser = 2, stricter = 4; default 3) — the only way to change sensitivity, never asked upfront. On accept, re-run Steps 3–5 with the new `k` (the `3` in the query).

## Schema

### Method
Expected range = trailing moving average ± `k`·stddev over a window that excludes the current bucket (so a spike can't inflate its own band). `k` is the sensitivity threshold, in standard deviations; default `k = 3` (≈1 false flag per 370 normal points). Window `W` by granularity — a whole number of cycles:

| Granularity | Window `W` |
|---|---|
| day | 28 (4 weeks) |
| week | 13 (a quarter) |
| month | 12 (a year) |
| quarter | 8 (two years) |

The first `W` buckets have no full window → `rolling_*` and `z_score` come back null (not flagged, shown as gaps). If the series is shorter than `W + 1` points, shrink `W` to about half the available history (minimum 4) and say so. With fewer than 8 points total, stop: *"Not enough history (n=X) to detect anomalies."*

### Anomaly query (AQL template — Step 3)
Write this AQL yourself, substituting `M`, `T`, `W` (and folding in any filters/timeframe). Each column:
• **bucket** — the period date (`T` truncated to `<granularity>`).
• **actual** — the metric `M` for that bucket.
• **rolling_mean** / **rolling_stddev** — mean / stddev of `actual` over the `W` buckets *immediately before* the current one (trailing window `-W..-1`, excludes the current bucket).
• **lower_bound** / **upper_bound** — `rolling_mean ∓ 3 * rolling_stddev`.
• **z_score** — `safe_divide(actual - rolling_mean, rolling_stddev)` (null when `rolling_stddev` is null or zero — never divide by zero).
• **is_anomaly** — `1` when `abs(z_score) > 3`, else `0` (the `3` is `k`; see Method).

```aql
explore {
  dimensions {
    bucket: T
  }
  measures {
    actual: M,
    rolling_mean: window_avg(M, -W..-1, order: T | asc(), partition: []),
    rolling_stddev: window_stdev(M, -W..-1, order: T | asc(), partition: []),
    lower_bound: window_avg(M, -W..-1, order: T | asc(), partition: []) - 3 * window_stdev(M, -W..-1, order: T | asc(), partition: []),
    upper_bound: window_avg(M, -W..-1, order: T | asc(), partition: []) + 3 * window_stdev(M, -W..-1, order: T | asc(), partition: []),
    z_score: safe_divide(M - window_avg(M, -W..-1, order: T | asc(), partition: []), window_stdev(M, -W..-1, order: T | asc(), partition: [])),
    is_anomaly: case(when: abs(safe_divide(M - window_avg(M, -W..-1, order: T | asc(), partition: []), window_stdev(M, -W..-1, order: T | asc(), partition: []))) > 3, then: 1, else: 0),
  }
  filters {
    // Timeframe filter. The parentheses around the time expression are REQUIRED:
    // `@(last 24 months)` — NOT `@last 24 months`.
    T matches @(last <N> <unit>)
  }
  sorts {
    bucket asc nulls last
  }
}
```

**Timeframe filter syntax:** write it exactly as `T matches @(last <N> <unit>)` — e.g. `mou_monthly_mrr.month matches @(last 24 months)`. The `@( … )` parentheses are mandatory; `matches @last 24 months` (no parens) fails with *"Syntax error … Expected one of …"*. Omit the `filters` block entirely only if the user asked for full history.

### Anomaly chart (CombinationChart template — Step 4)
"Self-contained" is the whole trick: the chart defines its own ad-hoc fields (`rolling_mean`, `rolling_stddev`, `lower_bound`, `upper_bound`, `z_score`, `is_anomaly`) as `calculation` blocks and reads the metric/time straight from the dataset, so it does not depend on the Step 3 result. Call `execute_viz` with only `dataset_uname`, `viz`, and `title` — never an `aql` property (it's rejected).

**The `calculation` blocks are MANDATORY — never drop them.** Every series/tooltip that uses `ref: '<name>'` resolves to the `calculation` of that name defined above it; omit them and the refs point at nothing and rendering fails (*"Referencing to an invalid biz calculation field"*). Emit all six. Do not reference the Step 3 result's internal column aliases (e.g. `mmm_m_dab06d`) — use the dataset field via `ref: r(<field>)` and calculations via `ref: '<calc_name>'`.

**Emit the block below, substituting the placeholders** — `<dataset>`, `<M>`, `<T>`, `<W>`, `<metric label>`, the number `pattern`, and **every `__ENDF__` → a double-semicolon** that ends the `@aql` formula. Don't otherwise restructure it — this exact form is known-good, and improvising it is what breaks rendering. Two easy-to-miss requirements: the `dataset:` property (required, separate from the `dataset_uname` you pass to `execute_viz`) and commas between the `tooltips` array elements. It is a `CombinationChart` (not a `LineChart`): three line series on the left axis plus a column series on a secondary 0..1 right axis. Keep the 6-digit `#DC2626` (the 8-digit alpha hex `#DC26264D` can be rejected by the renderer).

```aml
CombinationChart {
  dataset: <dataset>
  // Define the band/flag as calculations INSIDE the chart (self-contained) — this is what
  // binds them. Calculations may reference each other (lower_bound uses rolling_mean and
  // rolling_stddev, is_anomaly uses z_score). IMPORTANT: `__ENDF__` marks the end of each
  // @aql formula — when you emit the chart, replace EVERY `__ENDF__` with a double-semicolon
  // terminator (the two-character marker that ends an @aql formula). It is shown as a token
  // here because a real terminator would close this skill's own text block.
  calculation rolling_mean   { label: 'Rolling Mean'   formula: @aql window_avg(<M>, -<W>..-1, order: <T> | asc(), partition: [])__ENDF__ calc_type: 'measure' data_type: 'number' }
  calculation rolling_stddev { label: 'Rolling Stddev' formula: @aql window_stdev(<M>, -<W>..-1, order: <T> | asc(), partition: [])__ENDF__ calc_type: 'measure' data_type: 'number' }
  calculation lower_bound    { label: 'Lower Bound'    formula: @aql rolling_mean - 3 * rolling_stddev__ENDF__ calc_type: 'measure' data_type: 'number' }
  calculation upper_bound    { label: 'Upper Bound'    formula: @aql rolling_mean + 3 * rolling_stddev__ENDF__ calc_type: 'measure' data_type: 'number' }
  calculation z_score        { label: 'Z Score'        formula: @aql safe_divide(<M> - rolling_mean, rolling_stddev)__ENDF__ calc_type: 'measure' data_type: 'number' }
  calculation is_anomaly     { label: 'Is Anomaly'     formula: @aql case(when: abs(z_score) > 3, then: 1, else: 0)__ENDF__ calc_type: 'measure' data_type: 'number' }
  // Dataset fields use ref: r(<field>); calculations use ref: '<calc_name>'.
  x_axis: VizFieldFull { ref: r(<T>) label: 'Period' transformation: 'datetrunc month' format { type: 'date' pattern: 'LLL yyyy' } uname: 'bucket' }
  y_axis {
    label: '<metric label>'
    settings { alignment: 'left' scale: 'linear' }
    series { mark_type: 'line' field: VizFieldFull { ref: r(<M>) label: 'Actual' format { type: 'number' pattern: '[$$]#,###0' } } settings { color: '#2563EB' line_style: 'solid' } }
    series { mark_type: 'line' field: VizFieldFull { ref: 'lower_bound' label: 'Lower Bound' format { type: 'number' pattern: '[$$]#,###0' } } settings { color: '#9CA3AF' line_style: 'dashed' } }
    series { mark_type: 'line' field: VizFieldFull { ref: 'upper_bound' label: 'Upper Bound' format { type: 'number' pattern: '[$$]#,###0' } } settings { color: '#6B7280' line_style: 'dashed' } }
  }
  y_axis {
    label: 'Anomaly'
    settings { alignment: 'right' scale: 'linear' axis_min: 0 axis_max: 1 }
    series { mark_type: 'column' field: VizFieldFull { ref: 'is_anomaly' label: 'Is Anomaly' format { type: 'number' pattern: '#,###0' } } settings { color: '#FCA5A5' } }
  }
  // tooltips is an ARRAY — elements MUST be comma-separated.
  tooltips: [
    VizTooltip { field: VizFieldFull { ref: r(<M>) label: 'Actual' format { type: 'number' pattern: '[$$]#,###0' } } },
    VizTooltip { field: VizFieldFull { ref: 'rolling_mean' label: 'Rolling Mean' format { type: 'number' pattern: '[$$]#,###0' } } },
    VizTooltip { field: VizFieldFull { ref: 'z_score' label: 'Z Score' format { type: 'number' pattern: '#,###0.0' } } },
    VizTooltip { field: VizFieldFull { ref: 'is_anomaly' label: 'Is Anomaly' format { type: 'number' pattern: '#,###0' } } }
  ]
  settings {
    show_data_points: false
    connect_discontinuous_points: false
    sort: LineFamilySort { type: 'xaxis' direction: 'asc' }
  }
}
```

## Conventions
- **Write the AML yourself — never `generate_aql` / `generate_viz`.** This skill gives you exact templates (Schema); filling them in and running `execute_*` is faster and exact, with `validate_aql` as the syntax check before `execute_aql`. The two-step chain: (1) the anomaly AQL — actual + rolling stats + band/z/flag, all in one — `validate_aql`, `execute_aql` → anomaly results; (2) the self-contained `CombinationChart`, `execute_viz`.
- **On an error, consult the docs once, then retry once.** If a step errors (especially an AQL window-function or viz syntax error), call `search_docs` with the error / feature, fix the AML, then `execute_*` exactly once more. If it still fails, use the step's fallback: Step 3 → surface the error (don't pretend detection completed); Step 4 → fall back to the Step 3 `execute_aql` table + prose. Never loop more than one doc-lookup + one retry per step.
- **Titles.** `execute_aql` / `execute_viz` require a `title` (under ~60 chars; avoid "query 1"/"untitled"):

  | Call site | Title pattern |
  |---|---|
  | Step 3 anomaly results `execute_aql` | `<metric> anomaly results (<resolved timeframe>)` |
  | Step 4 anomaly chart `execute_viz` | `Anomaly detection: <metric> (<resolved timeframe>)` |

- **Handling truncated results.** If the MCP returns `@TruncatedContext:<chunk_id>` placeholders, call `fetch_context(chunk_id=<id>)` for each before reasoning over the data. Daily metrics over multi-year timeframes are the typical trigger.
- **Don't persist the rolling fields as model fields.** `rolling_mean` / `z_score` / `is_anomaly` depend on windowed (post-aggregation) results; as `dimension`/`measure` fields on the model they evaluate in the wrong semantic layer. Keep them in the ad-hoc query / viz.

### Numeric formatting
- Currency-like measures (label/name contains `revenue`, `cost`, `price`, `arr`, `mrr`, `gmv`, `amount`): `$` prefix, short suffix (`$500K`, `$1.2M`); use the dataset's stated currency symbol if metadata provides it.
- Counts and rates: thousands separators (`1,234`); rates to two significant decimals (`3.42%`).
- z-scores: one decimal place (`11.4`).

### Edge cases
In-flow stop conditions live at their step (insufficient history → Schema → *Method*; no data / unclassifiable `focus_date` → Step 5). The cases below are cross-cutting:

| Situation | Behavior |
|---|---|
| `list_datasets()` errors (e.g. "not supported in development mode") | Ask the user to name the dataset explicitly. Do not proceed. |
| Metric name matches no measure | Show top-3 closest measure names with descriptions; ask the user. |
| Step 3 `execute_aql` errors | Fix the AML (`validate_aql` / `search_docs` for the right syntax) and re-run once; if it still fails, stop and surface the error. A transient `UNION types text and numeric cannot be matched (SQLSTATE 42804)` (from the rollup grand-total row) usually clears on a re-run — just retry once. |
| Step 4 chart: `Referencing to an invalid biz calculation field` / a reference error on `lower_bound`, `is_anomaly`, etc. | The chart is missing the `calculation` block for that field (or you referenced a Step-3 column alias like `mmm_m_dab06d`). Add all six `calculation` blocks inside the `CombinationChart`; reference dataset fields via `ref: r(<field>)`, calculations via `ref: '<calc_name>'`. Re-run once. |
| Step 4 chart: `contains additional properties ["aql"]` | You passed `aql` to `execute_viz` — remove it; pass only `dataset_uname`, `viz`, `title`. For viz-syntax errors, `search_docs` and re-run once, then fall back to the Step 3 table + prose. |
| User asks "why did this happen?" or "what dimension drove it?" | Reply: "I can flag which points are statistically unusual, but identifying which dimension drove an anomaly — or its business cause — is outside this skill. Break the metric down by relevant dimensions in a dashboard, or check your marketing calendar / CRM / news for that window." |
| User asks to "show the raw numbers" or wants the per-bucket table | Show the `execute_aql` anomaly results directly (already a table) — `bucket`, `actual`, `rolling_mean`, `lower_bound`, `upper_bound`, `z_score`, `is_anomaly`. Never group/pivot rows by `is_anomaly`. |
