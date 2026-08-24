---
name: detect-anomaly
description: |-
  Detect statistical anomalies across a metric's history and visualize them: unusual spikes, drops, and deviations flagged against an expected range built from the metric's own history.

  Use when the user wants to find or check for unusual values in a metric. Trigger words include anomaly, unusual, spike, drop, dip, outlier, "out of the ordinary", "anything weird". A specific date is optional; the skill always scans the whole series.

  Typical phrasings: detect anomalies in revenue, any outliers in daily signups, has anything looked unusual in MRR lately, were there spikes or drops in active users this quarter, is revenue on May 20 unusual (a focus date; still scans the full series), or /detect_anomaly with no args (the skill asks for the metric).

  Do NOT trigger for: dimensional attribution (which segment or dimension drove an anomaly), explaining the business cause, or ongoing/scheduled monitoring & alerting. This skill flags which points are statistically unusual and shows them; it does not explain why.
user-invocable: false
---

Build an expected band from a metric's history, flag the buckets that break out of it, and chart the result. This skill identifies which points are unusual, not why they moved (Conventions → *Out of scope*).

Two sub-skills carry the mechanics: **`detect-anomaly-aql`** owns the method and the query, **`detect-anomaly-viz`** owns the chart.

## What a good input looks like

Anomaly detection compares a metric against its own history to determine whether a value is far from what the preceding periods would suggest. The analysis needs one measure, the date field and grain it is measured on, and enough prior history to establish what normal movement looks like.

A task is fully specified when you can answer:

1. **Which measure, and which dataset.** The method compares a series against itself, so it runs on exactly one measure; two measures are two analyses. When a chart offers several, ask which one, because choosing for the user wastes the whole run.
2. **Which date field, and at what grain.** Day, week, month, or quarter. The grain sets what can be found: a spike lasting two days does not show up in monthly buckets, and a metric recorded monthly cannot be read daily.
3. **Which slice of the data.** The segment in view, if any. The result describes the series you selected, not the business as a whole: one region collapsing can leave the company total flat, and a flat total can hide two segments moving in opposite directions. One slice per analysis; breaking the metric down by a dimension is a different question.
4. **Which period the findings cover.** Flagged buckets are reported only inside this period. Earlier buckets are shown as context, because the method needs prior history before it can judge a bucket.
5. **Whether the user has a specific date in question.** A named date does not narrow the analysis; the whole series is always scanned. It changes what the answer leads with — and, when that bucket falls in the lead-in, whether there is a verdict to lead with at all.

The user rarely supplies all five, and often has not asked for anomaly detection by name.

- **Read before asking.** A chart in view already carries the measure, date field, grain, slice and window; take them from there (*Resolving the spec*).
- **Ask only where a wrong guess wastes the run**: the measure, and with no chart its dataset. Derive the rest and state it back in one line with real dates, so a misread is cheap to correct.

## What a bare minimum output looks like
One chart and a prose summary.
- **The anomaly chart** (Step 3), per `detect-anomaly-viz`. It is required output; the run ships with it or says why it could not be drawn.
- **The prose summary** (Step 4), for a business reader: what an anomaly means here, then each flagged bucket with its date, value, direction, and how far outside the band it fell.
- **The anomaly results** (Step 2) stay internal. They are the summary's source of truth, not a table to show, unless the user asks for the raw numbers.

## Workflow

Four steps. Each is a move an analyst makes, and each closes with a `post_update` so the user follows the reasoning as it happens instead of receiving a verdict at the end. **Narrating is not pausing**: post and keep working. The only stop in the run is the measure question in Step 1.

Placeholders: `M` = the metric measure (e.g. `gmv`), `T` = the bound time dimension (e.g. `bq_fct_order_items.created_date`), `<grain>` = the time grain, `k` = the sensitivity threshold, `<dataset>` = the dataset name, `<metric label>` = a readable label.

### Step 1: Establish the series

A series needs one measure on one time axis, at one grain, for one slice, over one period. Read it from the chart rather than asking for it back.

Resolve the spec (*Resolving the spec*): ask only for what's still empty — at most the measure, and with no chart its dataset. Confirm only what you guessed, then wait; fields read from the chart or stated by the user are accepted silently.

Post the metric, grain, slice and period as real dates, and that the whole series is scanned even if the user named a single date. The data checks — missing buckets, a final bucket still in progress, row count — are read off the Step 2 results.

### Step 2: Run the detection

The rule: predict each period from where the metric's movement so far was heading, then judge the gap between actual and prediction against how much this metric usually moves period to period. There is no baseline length to choose — every period is judged against everything before it. `detect-anomaly-aql` owns the method and the query.

Hand over the resolved parameters:

```
/detect-anomaly-aql

M: ...
T: ...
grain: ...
k: ...
reporting: ...
filters: ...
```

Run `execute_aql` on what comes back (title per Conventions → *Titles*). Those are the **anomaly results**, the summary's source of truth; the AQL itself goes to Step 3 unchanged.

Read the returned rows for the four conditions that change what you can promise:
- **Missing buckets** between the first and last. Gaps break the period-to-period comparison the method rests on.
- **A final bucket still in progress.** A part-period value reads as a collapse. Exclude it, or say it is incomplete.
- **Row count.** A short series is not an error: it comes back unassessed rather than flagged. Say so instead of reporting that nothing was unusual.
- **The focus bucket's `verdict`, when the user pointed at one.** `not assessed` means the run cannot answer the question it was asked, however much of the rest of the series came back judged. Read it here rather than while writing the summary: it decides what the answer leads with.

Then post the rule in the reader's terms, naming `k`, and anything the four checks turned up.

### Step 3: Draw the anomaly chart

Draw it even when nothing is flagged: without the band, "nothing was unusual" is an assertion the reader has no way to check. This is the run's only chart, so it carries the series as well as the band.

**Delegate this step to a sub-agent.** Do not draw the chart yourself. Hand off:

```
/detect-anomaly-viz

dataset: ...
aql: <the Step 2 explore, verbatim>
grain: ...
metric label: ...
```

Then post the anomaly definition, so it lands with the band already on screen:
> **What counts as unusual here.** An anomaly is any [grain] whose value departs sharply from where the trend was heading: a change much larger or smaller than [metric]'s normal [grain]-to-[grain] movement across its history up to that point.

Then post how to read it: the band is the expected range given the trend so far, it widens when movement has been erratic, and the red columns mark what broke out.

### Step 4: Write the summary

Read `verdict`. It is one field per bucket carrying one of three words, and it is the only thing that decides how a bucket is treated:

| `verdict` | What it is |
|---|---|
| `unusual` | A finding. These are what the summary lists. |
| `normal` | Assessed, nothing to report. |
| `not assessed` | Context, never a finding — too little history behind it, or no variation to judge against. |

Do not infer any of this from `z_score` or `anomaly_flag`. `anomaly_flag` is `0` for both `normal` and `not assessed`, which is exactly the confusion `verdict` exists to remove; it is the chart's column series, not an input to the prose. `z_score` is only for phrasing how far a finding fell outside the band.

Write the summary (Output → *Summary*) covering only what was assessed, not what was asked for: if any bucket in the period came back `not assessed`, name the span actually judged.

Before writing, check:
- `k` is the value from `detect-anomaly-aql`, never adjusted for this series.
- The anomaly chart was drawn (even when nothing was flagged), or the fallback was taken and said so.
- No causal or dimensional claim anywhere in the prose. Numbers per Conventions → *Numeric formatting*.

Two patterns in the flagged set change what the summary can claim:
- **Same calendar position** (same month each year, same weekday). The method has no seasonal term, so a recurring peak flags as an anomaly. Say so, and offer the seasonality-aware re-run.
- **A flag early in the series.** The baseline is every prior bucket, so an unusual value widens the band for everything after it and never falls back out. Anything milder later was judged against a looser threshold and may have been missed. Say so whenever the first flag lands well before the others.

## Output

### Summary (prose, Step 4)

A complete answer on the primary path (no focus date, two buckets flagged). The chart is not written, it is what `execute_viz` returned in Step 3; the prose below it is Step 4's:

> ⟦ Step 3 anomaly definition post_update renders here ⟧
>
> ⟦ Step 3 anomaly chart renders here ⟧
>
> **Found 2 unusual months in GMV, Jul 2023 to Aug 2024:**
>
> - **Nov 2023: $4.2M.** Above the expected trend by about 3.6× its normal monthly movement.
> - **Mar 2024: $1.9M.** Below the expected trend by about 4.1× its normal monthly movement.
>
> **What this does not tell you.** Why they moved, and which segment drove them, is outside this analysis. Break GMV down by product, channel or customer segment, and check the marketing calendar and CRM for those two windows.
>
> Want me to re-run with a stricter or looser threshold? Looser flags more months (milder deviations); stricter flags only the most extreme. A seasonality-aware version is also available if GMV has a repeating annual shape.

Then the conventions:

- **Register.** Business reader, plain and professional. No raw notation: no bare "σ", "z = 3.4", "3σ". `z` appears only as a spoken multiple, as above.
- **Markup carries the scan.** A bold label opens each part; each finding leads with its date and value in bold, then a plain sentence for the assessment. No headings, no tables.
- **One line per flagged bucket, chronological**, each carrying the date, the value, the direction, and how far outside the band it fell in plain terms.
- **The user has the chart.** Do not repeat the results as a table unless asked.
- **Report the assessed span, and no more.** The assessed span is the buckets whose `verdict` is not `not assessed`. Name it whenever it differs from the period that was asked for; findings and any "nothing unusual" claim cover that span only. The chart ships first in every case. Four shapes fall out of the one rule:
  - *Fully assessed, nothing flagged* — *"No unusual values in GMV over Jul 2023 to Aug 2024; every month moved in line with the trend up to it."*
  - *Partly assessed* — *"Assessed GMV from Jul 2024 onward; the months before it had too little history behind them."*
  - *Nothing assessed* — every bucket came back `not assessed`. *"Not enough history to assess GMV. The method needs a few months of movement behind a month before it can judge it, and this series starts in Nov 2025."* Never that nothing was unusual. When the cause is a flat series rather than a short one, say that instead: *"GMV held at exactly $40K every month, so there is no variation to judge a month against."*
  - *A named date outside the assessed span* — lead with that, then the list for what was assessed: *"I can't judge Feb 2026 — it is one of the opening months of the series, and the method needs a few months of movement behind a month before it can judge it. GMV starts in Jan 2026."*
- **A named date inside the assessed span**: lead with the verdict on that bucket, unusual or normal, then the same list. The full series is scanned either way.
- **The closing pointer** appears only when something was flagged.
- **The re-run offer goes last.** `k` is the only sensitivity control and is never asked upfront (values in `detect-anomaly-aql`). On accept, re-run Steps 2 to 4 with the new `k`.

## Resolving the spec

Produce one spec `{ dataset, M, T, granularity, filters, timeframe }`. **One fill pass, not a chart path and a typed path**: take each field from the chart when there is one, let the user's words override anything they spoke to ("…but over the last 3 years", "…just the West region"), then fall back to defaults, and ask only for what is still empty.

| Field | From the chart's Viz AML | Otherwise |
|---|---|---|
| `dataset` | the viz `dataset:` | a ranked measure search; ask if nothing matches |
| `M` | the y-axis measure | the user's words; if a typed metric matches no measure, show the top-3 closest and ask |
| `T` + `granularity` | the x-axis field and its `transformation` (`datetrunc month` → month) | `granularity` derived from `T` |
| `filters` | `filter` / `filter_groups` / `conditions`, **excluding** the time-range filter | none |
| `timeframe` | the chart's timeframe | per grain: `day`→90d, `week`→26w, `month`→24m, `quarter`→12q |

- **More than one y-axis measure**: ask which to analyze (list them and wait), unless the user already named one.
- **`M` is a viz-level `calculation`**, not a dataset measure: carry its `@aql` formula and inline it as `metric M = <formula>;` in the Step 2 query.
- **The x-axis is not a time field**: this is not a time series. Ask for the metric and grain instead; do not proceed.
- **A legend/breakdown**: drop it and analyze the total, unless the user explicitly asks per-segment (Conventions → *Out of scope*).
- **No chart, and the metric cannot be parsed**, or `list_datasets()` is unsupported (dev mode): ask the user to name the dataset and metric explicitly. Do not proceed.
- **Confirm only what you guessed** (*"I'll use `sales_orders` (measure `total_revenue`). Confirm, or name another."*), then wait. Fields read from the chart or stated by the user are accepted silently.
- The timeframe resolved here is the **reporting** window: what the findings cover. `detect-anomaly-aql` queries the series from its start regardless, because the baseline is every prior bucket; the buckets before the reporting window are context on the chart and are never reported as findings.

## Conventions
- **On an error, retry once, then fall back.** Step 2: surface the error, never imply detection completed. Step 3: fall back to the Step 2 table plus prose. Never loop more than one retry per step.
- **Titles.** `execute_aql` / `execute_viz` require a `title` (under ~60 chars; avoid "query 1"/"untitled"): Step 2 anomaly results → `<metric> anomaly results (<reporting timeframe>)`; Step 3 anomaly chart → `Anomaly detection: <metric> (<reporting timeframe>)`.

### Numeric formatting
- Currency-like measures (label/name contains `revenue`, `cost`, `price`, `arr`, `mrr`, `gmv`, `amount`): `$` prefix, short suffix (`$500K`, `$1.2M`); use the dataset's stated currency symbol if metadata provides it.
- Counts and rates: thousands separators (`1,234`); rates to two significant decimals (`3.42%`).
- z-scores / multiples: one decimal place (`3.4`).

### Out of scope
This skill says which points broke from the trend. It does not say why, and it does not attribute a break to a segment.
- **"Why did this happen?" / "What dimension drove it?"** Reply: "I can flag which points broke from the trend, but identifying which dimension drove an anomaly, or its business cause, is outside this skill. Break the metric down by relevant dimensions in a dashboard, or check your marketing calendar / CRM / news for that window."
- **A per-segment run.** Out of scope: one slice per analysis. Offer a separate run on the segment the user names.
- **"Show the raw numbers."** Show the `execute_aql` anomaly results directly: `bucket`, `actual`, `expected`, `lower_bound`, `upper_bound`, `z_score`, `verdict`. Drop `anomaly_flag` — it duplicates `verdict` for the chart's benefit. Never group or pivot rows by `verdict`.
