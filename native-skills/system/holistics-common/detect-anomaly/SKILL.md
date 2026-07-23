---
name: detect-anomaly
label: Detect anomaly
description: |-
  Detect statistical anomalies across a metric's history and visualize them — unusual spikes, drops, and deviations flagged against an expected range built from the metric's own recent history.

  Use when the user wants to find or check for unusual values in a metric — words like anomaly, unusual, spike, drop, dip, outlier, "out of the ordinary", "anything weird". A specific date is optional; the skill always scans the whole series.

  Typical phrasings: detect anomalies in revenue, any outliers in daily signups, has anything looked unusual in MRR lately, were there spikes or drops in active users this quarter, is revenue on May 20 unusual (a focus date — still scans the full series), or /detect_anomaly with no args (the skill asks for the metric).

  Do NOT trigger for: dimensional attribution (which segment or dimension drove an anomaly), explaining the business cause, or ongoing/scheduled monitoring & alerting. This skill flags which points are statistically unusual and shows them; it does not explain why.
---

Flag which points in a metric's time series moved unusually against its own recent trend, and show them: build a trend-following expected band from recent history, flag the buckets that break out of it, and visualize the result. This skill flags *which* points are unusual, never *why* — deflect causal or dimensional-attribution asks (Conventions → *Edge cases*).

## What a good input looks like
An anomaly task scans one metric's time series against a trend-following band built from its own recent history. The primary path is **chart-anchored**: the user is viewing a chart and asks whether its movement is normal, so the fields below are read from that chart's Viz AML. Only `metric` is truly required — derive or default the rest, then echo everything back (with the resolved timeframe as an absolute range) so the user can correct a mis-parse.

- **`metric` (`M`)** — *required*. From the viewed chart's y-axis measure; else the user's words. If missing, ask — don't guess. If the chart carries **more than one** y-axis measure, ask which one to analyze (don't default to the first).
- **`dataset`** — *required*. From the chart's `dataset:`; else a ranked measure search. If missing, ask.
- **`time axis` (`T`) + `granularity`** — inferred from the chart's x-axis field and its `datetrunc` transformation. If the x-axis isn't a time field, ask for the metric + time grain.
- **`filters`** — optional. The chart's dimensional filters (not its time range).
- **`focus_date`** — optional. From the user's words; changes only the closing prose.
- **`timeframe`** — optional. The chart's timeframe; else default by grain (`day`→90d, `week`→26w, `month`→24m, `quarter`→12q).

Fill these with **one prioritized-fill pass**, not a chart-vs-typed branch (Workflow → *Step 1*). Confirm only fields you had to **guess**; silently accept fields **read** from the chart or stated by the user.

## What a bare minimum output looks like
The deliverable is a trend-anomaly chart plus a short prose summary — nothing else by default.
- **The chart** (Step 3): `actual` as a solid blue line, the `lower_bound`/`upper_bound` trend band dashed grey, and `is_anomaly` as red columns on a secondary 0..1 axis, with tooltips.
- **The prose summary** (Step 3): for a business reader — defines an anomaly (a break from the recent trend), then lists each flagged bucket (date, value, above/below the trend, how far out in plain terms).
- **The anomaly results** (the Step 2 AQL) stay internal — the source of truth for the summary, not shown as a table unless the user asks for the raw numbers.
- If `execute_viz` ultimately fails, fall back to the Step 2 table + prose (Conventions → *On an error*).

## Workflow
Three steps, in order. Hand-write the AQL yourself (Step 2) — the method must be exact — but author the chart with `generate_viz` (Step 3): hand-written viz grammar is the top source of invalid output. `execute_aql` runs the AQL (and validates it on execution); `execute_viz` runs the chart.

Placeholders: `M` = the metric measure (e.g. `gmv`), `T` = the bound time dimension (e.g. `bq_fct_order_items.created_date`), `<grain>` = the time grain, `W` = the window for the grain, `k` = the sensitivity threshold (default 3), `<dataset>` = the dataset name, `<metric label>` = a readable label.

### Step 1 — Resolve the input
Produce one detection spec `{ dataset, M, T, granularity, filters, timeframe }`. Fill each field from the strongest available source, in precedence order — there is **no chart-path-vs-typed-path branch**:
1. **The active chart's Viz AML** (the runtime hands the AI the AML of the chart the user is viewing) — fills `dataset`, `M`, `T`, `granularity`, `filters`, and the chart's timeframe.
2. **The user's words** — fill or *override* any field they spoke to ("…but over the last 3 years", "…just the West region", or, with no chart, the metric name itself).
3. **Dataset metadata + defaults** — `granularity` from `T`; timeframe default per grain.
4. **Ask the user** — only for a field still empty (realistically `M`/`dataset` with no chart and no parseable metric).

**Reading the chart's Viz AML** (source 1) — pull each field out of the attached AML:
- `dataset` ← the viz `dataset:`.
- `M` ← the y-axis measure. If the chart has **more than one** y-axis measure, don't pick for the user — **ask which one** to analyze (list them and wait), unless the user already named one in their words. Anomaly detection runs on a single series, and silently choosing the wrong one wastes the whole run. With exactly one y-axis measure, use it. If `M` is a viz-level `calculation` rather than a dataset measure, carry its `@aql` formula and inline it as `metric M = <formula>;` in the Step 2 query.
- `T` + `granularity` ← the x-axis field and its `transformation` (`datetrunc month` → grain = month). If the x-axis is **not** a time field, this isn't a time series → fall back to typed/ask.
- `filters` ← the viz `filter` / `filter_groups` / `conditions`, **excluding** the time-range filter.
- **Legend/breakdown** → collapse to the total (drop the legend) unless the user explicitly asks per-segment (per-segment is out of scope — Conventions → *Edge cases*).
- **Timeframe + warm-up** — the reporting timeframe is what gets flagged/reported; the Step 2 query widens it by `W` buckets on the leading edge so the reporting window is fully banded. The chart shows those `W` lead-in buckets as trend context (unbanded); prose reports only within the reporting timeframe.

Confirm only fields you **guessed** (a ranked search: *"I'll use `sales_orders` (measure `total_revenue`). Confirm, or name another."* — then wait); silently accept fields **read** from the chart or stated by the user. Validate that `M` exists as a measure (or is a carried viz calculation); if a typed metric matches none, show the top-3 closest measures and ask. Echo the resolved slice back, including the lead-in context: *"Analyzing GMV for Region = West over Jul 2023 – Aug 2024 (your view); the chart also shows earlier months as lead-in to establish the trend."*

### Step 2 — Detect (write AQL → execute_aql)
Write the anomaly AQL from Output → *Method* and *Anomaly query*, substituting `M`, `T`, `<grain>`, `W`, `k`, folding in the dimensional filters, and widening the timeframe by `W` buckets for warm-up. Then `execute_aql` (title per Conventions → *Titles*) — it validates the AQL on execution and errors loudly on a bad query. The result is the **anomaly results** — the summary's source of truth and the exact AQL you hand to `generate_viz` in Step 3.

### Step 3 — Present (generate_viz → execute_viz → summarize)
Feed the Step 2 AQL to `generate_viz` per Output → *Anomaly chart*, adjust only decoration, then `execute_viz` (title per Conventions → *Titles*). Then write the prose per Output → *Summary*, reading only the buckets inside the reporting timeframe. On a failure, Conventions → *On an error*.

## Output

### Method
The expected band **follows the trend**. For each bucket `t` (`T` truncated to `<grain>`):
- `actual` = `M`; `Δ` = the change from the previous bucket.
- `expected` = previous actual **+ drift**, where drift = the trailing mean of `Δ` over the `W` buckets before `t`. This is the band's centre; it tilts with the trend.
- `spread` = the trailing **stddev of `Δ`** over those `W` buckets.
- `lower/upper_bound` = `expected ∓ k · spread`.
- `z_score` = `(actual − expected) / spread` — is *this bucket's change* unusual versus the recent distribution of changes (stationary even when the level trends).
- `is_anomaly` = `1` when `abs(z_score) > k`, else `0`. `k` default 3 (looser 2, stricter 4).

**Warm-up gate (required).** A bucket is only banded/flagged once it has a **full `W`-bucket window** of prior history. Partial-frame window stats return values (not null), so gate explicitly on `n_prior = window_count(...) ≥ W`: buckets with `n_prior < W` get **no band** and are **never flagged** — the leading `W` lead-in buckets are exactly these, shown as context.

Window `W` by grain — a whole number of cycles:

| Grain | `W` |
|---|---|
| day | 28 (4 weeks) |
| week | 13 (a quarter) |
| month | 12 (a year) |
| quarter | 8 (two years) |

If the series is shorter than `W + 1`, shrink `W` to about half the available history (minimum 4) and say so. With fewer than 8 points total, stop: *"Not enough history (n=X) to detect anomalies."*

### Anomaly query (AQL template — Step 2)
Write this yourself. `M`, `T`, `<grain>`, `W`, `k` are placeholders; the `-1..-1` range (previous bucket) is literal; every `window_*` call takes `order: T | <grain>() | asc(), partition: []`. Widen the timeframe filter by `W` buckets, and add any dimensional filters. (Validated against `demo_bigquery_ecommerce`/`gmv`.)

```aql
metric m_prev   = window_avg(M, -1..-1,  order: T | <grain>() | asc(), partition: []);
metric m_delta  = M - m_prev;
metric m_n      = window_count(M, -W..-1, order: T | <grain>() | asc(), partition: []);
metric m_drift  = window_avg(m_delta, -W..-1,  order: T | <grain>() | asc(), partition: []);
metric m_spread = window_stdev(m_delta, -W..-1, order: T | <grain>() | asc(), partition: []);
metric m_expected = m_prev + m_drift;
metric m_z      = safe_divide(M - m_expected, m_spread);
metric m_lower  = case(when: m_n >= W, then: m_expected - k * m_spread, else: null);
metric m_upper  = case(when: m_n >= W, then: m_expected + k * m_spread, else: null);
metric m_anom   = case(when: and(m_n >= W, abs(m_z) > k), then: 1, else: 0);
explore {
  dimensions {
    bucket: T | <grain>()
  }
  measures {
    actual: M,
    expected: m_expected,
    lower_bound: m_lower,
    upper_bound: m_upper,
    z_score: m_z,
    is_anomaly: m_anom
  }
  filters {
    // reporting window WIDENED by W buckets for warm-up; the @( … ) parentheses are REQUIRED.
    T matches @(last <reporting + W> <grain>s)
    // + any dimensional filters carried from the chart, e.g. bq_fct_order_items.merchant_country_code == "US"
  }
  sorts {
    bucket asc nulls last
  }
}
```

**Do not regress these (spike-validated):**
- Count prior buckets with `window_count(M, -W..-1, …)` — **never** `window_sum(1, …)` (SQL-generation error).
- The `n_prior ≥ W` gate is mandatory (partial windows return values, not null, and would false-flag the first `W` buckets).
- `case(when: …, else: null)` is valid and is how the band is hidden in the lead-in.
- The nested window (`window_stdev(m_delta, …)` where `m_delta` contains a window) compiles directly — one explore, no two-stage query.

**Reference `M` bare.** A dataset metric (one defined in the dataset's `metric { … }` block — e.g. `gmv`, `count_users`) is referenced by its **bare name** in the AQL, never qualified as `<dataset>.<metric>` or `<model>.<metric>`. Qualifying it errors — *"Field `<metric>` … is referencing Model `<dataset>`, but the Model does not exist in Dataset"*. (If `M` is a viz-level `calculation` rather than a dataset metric, inline its `@aql` formula as `metric M = <formula>;` first, per Step 1.)

### Anomaly chart (generate_viz — Step 3)
Don't hand-write the `CombinationChart` — pass the Step 2 explore (verbatim) to `generate_viz` and **state the decoration explicitly in the `query`** (generate_viz defaults its palette and `pattern: 'inherited'` unless told otherwise, so name the colours):

1. `generate_viz(dataset_uname: <dataset>, aql: <the Step 2 explore, verbatim>, query: "Combination chart of <metric label> by <grain>: actual as a solid #255DD4 line; lower_bound and upper_bound as grey #9CA3AF dashed lines forming the expected band; is_anomaly as red #FCB8B8 columns on a secondary 0..1 right axis; x-axis is the <grain> bucket; format <metric label> as short-suffix currency like $500K; tooltips for expected, <metric label>, and z_score.")`.
2. Keep the structure `generate_viz` produced (axes, series, calculations); adjust only decoration. Keep 6-digit hex (an 8-digit alpha hex can be rejected).
3. `execute_viz(dataset_uname: <dataset>, viz: <the adjusted viz>, title: …)` — pass only these three, no `aql` property.

If `execute_viz` errors, feed the error text back into `generate_viz`'s `query` (it self-corrects from prior errors) and retry once; if it still fails, fall back to the Step 2 `execute_aql` table + prose.

### Summary (prose — Step 3)
For a business reader: plain and professional, no raw notation (no bare "σ", "z = 3.4", "3σ"). Read the anomaly results; don't render them as a table (the user sees the chart) unless asked.

Open with one sentence defining an anomaly under this method, then the findings:

> *An anomaly is any <grain> whose value departs sharply from where its recent trend was heading — a change much larger or smaller than the metric's normal <grain>-to-<grain> movement over the prior <W> <grain>s.*

Classify each bucket in the reporting window:
- **Unusual** — `is_anomaly = 1`: above the trend (`actual > expected`) or below it.
- **Normal** — `is_anomaly = 0`, `z_score` non-null: moved in line with the trend.
- **Not enough history** — `z_score`/band null (a lead-in bucket, `n_prior < W`): shown as context without a band; not assessed.

Translate the statistics — describe the size of the surprise in plain terms (*"about <z> times its normal monthly swing"*), z only as a parenthetical.

No focus date (primary path):

> **Found <N> unusual <grain>(s) in <metric label>** over **<reporting timeframe>**:
> - **<date>** — <value>: **<above|below>** the expected trend (about <z>× its normal <grain> movement).
> - … one bullet per flagged bucket, chronological

If `N = 0`: *"No unusual values in <metric label> over <reporting timeframe> — every <grain> moved in line with its recent trend."*

Focus date given: lead with the verdict on that bucket, then the same list.
- Unusual: *"**<metric label> on <date> = <value>** is unusual — it broke **<above|below>** its recent trend (about <z>× the normal <grain> movement)."*
- Normal: *"**<metric label> on <date> = <value>** moved in line with its recent trend — not unusual."*
- Lead-in / no band: *"Not enough prior history to assess <date> — it's within the first <W> <grain>s, shown as context without a band."*

Closing pointer (N ≥ 1): why an anomaly happened or which dimension drove it is out of scope — invite the user to investigate via a dimensional breakdown and business context (marketing calendar, CRM, recent news).

Post-run override (offer last): *"Want me to re-run with a stricter or looser threshold? Looser flags more <grain>s (milder deviations); stricter flags only the most extreme. A seasonality-aware version (for weekly/annual patterns) is also available."* The threshold is `k` (looser = 2, stricter = 4; default 3) — the only sensitivity control, never asked upfront. On accept, re-run Steps 2–3 with the new `k`.

## Conventions
- **Hand-write the AQL; let `generate_viz` author the chart.** The Step 2 AQL is deterministic and encodes the method exactly — write it yourself and run it with `execute_aql` (which validates it on execution). The chart is the opposite: hand-written viz grammar is the top source of invalid output, so pass your AQL to `generate_viz` and adjust only decoration. (Don't use `generate_aql` — the method must be exact, so the AQL is authored by hand.)
- **On an error, retry once, then fall back.** If the AQL errors, `search_docs` for the fix and re-run `execute_aql` once. If the chart errors on `execute_viz`, feed the error text back into `generate_viz`'s `query` and re-run once. If a retry still fails: Step 2 → surface the error (don't pretend detection completed); Step 3 → fall back to the Step 2 table + prose. Never loop more than one retry per step.
- **Titles.** `execute_aql` / `execute_viz` require a `title` (under ~60 chars; avoid "query 1"/"untitled"): the Step 2 anomaly results `execute_aql` → `<metric> anomaly results (<reporting timeframe>)`; the Step 3 anomaly chart `execute_viz` → `Anomaly detection: <metric> (<reporting timeframe>)`.
- **Handling truncated results.** If the MCP returns `@TruncatedContext:<chunk_id>` placeholders, call `fetch_context(chunk_id=<id>)` for each before reasoning over the data. Daily metrics over multi-year timeframes are the typical trigger.
- **Don't persist the rolling fields as model fields.** `m_drift` / `m_spread` / `z_score` / `is_anomaly` depend on windowed (post-aggregation) results; as `dimension`/`measure` fields on the model they evaluate in the wrong semantic layer. Keep them in the ad-hoc query / viz.

### Numeric formatting
- Currency-like measures (label/name contains `revenue`, `cost`, `price`, `arr`, `mrr`, `gmv`, `amount`): `$` prefix, short suffix (`$500K`, `$1.2M`); use the dataset's stated currency symbol if metadata provides it.
- Counts and rates: thousands separators (`1,234`); rates to two significant decimals (`3.42%`).
- z-scores / multiples: one decimal place (`3.4`).

### Edge cases

| Situation | Behavior |
|---|---|
| Viz AML x-axis is not a time field | Not a time series — fall back to typed/ask for the metric + time grain. Don't proceed. |
| Viz has more than one y-axis measure | Ask the user which single measure to analyze (list them); don't default to the first. Skip the ask only if the user already named one. |
| Viz has a legend/breakdown | Collapse to the total (drop the legend) unless the user asks per-segment. |
| Series too short even with the lead-in (starts inside the window) | Earliest buckets show without a band (`n_prior < W`); if < 8 usable points, stop with the insufficient-history message. |
| Flat series (spread = 0) | `safe_divide` → `z_score` null; not flagged (never divide by zero). |
| Non-negative metric, band dips below 0 | Rare (the band is around the trend, not the level), but clamp the *displayed* lower bound at 0 for non-negative metrics. |
| Step 2 `execute_aql` errors | `search_docs` for the fix, re-run once; a transient rollup `UNION types text and numeric cannot be matched (SQLSTATE 42804)` usually clears on a re-run. If it still fails, stop and surface the error. |
| Step 3 chart errors on `execute_viz` | Feed the error text back into `generate_viz`'s `query` and re-run once. If it still fails, fall back to the Step 2 `execute_aql` table + prose. Don't hand-write the viz grammar. |
| `list_datasets()` unsupported (dev mode) or no chart + unparseable metric | Ask the user to name the dataset/metric explicitly. Do not proceed. |
| User asks "why did this happen?" or "what dimension drove it?" | Reply: "I can flag which points broke from the trend, but identifying which dimension drove an anomaly — or its business cause — is outside this skill. Break the metric down by relevant dimensions in a dashboard, or check your marketing calendar / CRM / news for that window." |
| User asks to "show the raw numbers" | Show the `execute_aql` anomaly results directly — `bucket`, `actual`, `expected`, `lower_bound`, `upper_bound`, `z_score`, `is_anomaly`. Never group/pivot rows by `is_anomaly`. |
