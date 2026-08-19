---
name: detect-anomaly
description: |-
  Detect statistical anomalies across a metric's history and visualize them: unusual spikes, drops, and deviations flagged against an expected range built from the metric's own recent history.

  Use when the user wants to find or check for unusual values in a metric. Trigger words include anomaly, unusual, spike, drop, dip, outlier, "out of the ordinary", "anything weird". A specific date is optional; the skill always scans the whole series.

  Typical phrasings: detect anomalies in revenue, any outliers in daily signups, has anything looked unusual in MRR lately, were there spikes or drops in active users this quarter, is revenue on May 20 unusual (a focus date; still scans the full series), or /detect_anomaly with no args (the skill asks for the metric).

  Do NOT trigger for: dimensional attribution (which segment or dimension drove an anomaly), explaining the business cause, or ongoing/scheduled monitoring & alerting. This skill flags which points are statistically unusual and shows them; it does not explain why.
user-invocable: false
---

Build an expected band from a metric's recent history, flag the buckets that break out of it, and chart the result. This skill identifies which points are unusual, not why they moved (Conventions → *Out of scope*).

Two sub-skills carry the mechanics: **`detect-anomaly-aql`** owns the method and the query, **`detect-anomaly-viz`** owns both charts.

## What a good input looks like

Anomaly detection compares a metric against its own recent history to determine whether a value is far from what the preceding periods would suggest. The analysis needs one measure, the date field and grain it is measured on, and enough prior history to establish what normal movement looks like.

A task is fully specified when you can answer:

1. **Which measure, and which dataset.** The method compares a series against itself, so it runs on exactly one measure; two measures are two analyses. When a chart offers several, ask which one, because choosing for the user wastes the whole run.
2. **Which date field, and at what grain.** Day, week, month, or quarter. The grain sets what can be found: a spike lasting two days does not show up in monthly buckets, and a metric recorded monthly cannot be read daily.
3. **Which slice of the data.** The segment in view, if any. The result describes the series you selected, not the business as a whole: one region collapsing can leave the company total flat, and a flat total can hide two segments moving in opposite directions. One slice per analysis; breaking the metric down by a dimension is a different question.
4. **Which period the findings cover.** Flagged buckets are reported only inside this period. Earlier buckets are shown as context, because the method needs prior history before it can judge a bucket.
5. **Whether the user has a specific date in question.** A named date does not narrow the analysis; the whole series is always scanned. It changes only what the answer leads with.

The user rarely supplies all five, and often has not asked for anomaly detection by name.

- **Read before asking.** A chart in view already carries the measure, date field, grain, slice and window; take them from there (*Resolving the spec*).
- **Ask only where a wrong guess wastes the run**: the measure, and with no chart its dataset. Derive the rest and state it back in one line with real dates, so a misread is cheap to correct.

## What a bare minimum output looks like
Two charts and a prose summary.
- **The series chart** (Step 1) and **the anomaly chart** (Step 3), both per `detect-anomaly-viz`. The anomaly chart is required output. The series chart is not: a failure there is noted and the run continues.
- **The prose summary** (Step 4), for a business reader: what an anomaly means here, then each flagged bucket with its date, value, direction, and how far outside the band it fell.
- **The anomaly results** (Step 2) stay internal. They are the summary's source of truth, not a table to show, unless the user asks for the raw numbers.

## Workflow

Four steps. Each is a move an analyst makes, and each closes with a `post_update` so the user follows the reasoning as it happens instead of receiving a verdict at the end. **Narrating is not pausing**: post and keep working. The only stop in the run is the measure question in Step 1.

Placeholders: `M` = the metric measure (e.g. `gmv`), `T` = the bound time dimension (e.g. `bq_fct_order_items.created_date`), `<grain>` = the time grain, `W` = the baseline window, always 12, `k` = the sensitivity threshold, `<dataset>` = the dataset name, `<metric label>` = a readable label.

### Step 1: Establish the series

Nothing can be called unusual until there is a definite series to judge: one measure, on one time axis, at one grain, for one slice, over one period. Almost all of that is already settled by whatever the user is looking at, so read it rather than asking for it back.

Then draw it. The chart confirms the resolved grain and slice, and it is the picture the expected band gets added to in Step 3.

Resolve the spec (*Resolving the spec*), then draw the series:

```
/detect-anomaly-viz

chart: series
dataset: ...
M: ...
T: ...
grain: ...
reporting: ...
metric label: ...
filters: ...
```

Read the returned rows for the three conditions that change what you can promise:
- **Missing buckets** between the first and last. Gaps break the period-to-period comparison the method rests on.
- **A final bucket still in progress.** A part-period value reads as a collapse. Exclude it, or say it is incomplete.
- **Row count.** A short series is not an error: it comes back unassessed rather than flagged. Say so instead of reporting that nothing was unusual.

Then post: the metric, grain, slice and period as real dates; that the metric will be judged against its own recent history and the whole series scanned even if the user named a single date; and anything the three checks turned up.

### Step 2: Turn "unusual" into a rule, and apply it

Eyeballing the chart is not detection. A rule has to say what each period was expected to be, and how much deviation is normal for this particular metric.

The rule: predict each period from where the last `W` periods of movement were heading, then judge the gap between actual and prediction against how much this metric usually moves period to period. `detect-anomaly-aql` owns it, including the baseline length and the full-window rule.

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

Run `execute_aql` on what comes back (title per Conventions → *Titles*). Those are the **anomaly results**, the summary's source of truth; the AQL itself goes to Step 3 unchanged. Then post the rule in the reader's terms, naming the baseline length and `k`.

### Step 3: Show the expectation, not just the verdict

The chart is the evidence for the verdict, whichever way the verdict goes: it shows where each period was expected to land, how wide normal was at that moment, and whether the series stayed inside. **A run that flags nothing needs it as much as one that flags three.** Without the band, "nothing was unusual" is an assertion the reader has no way to check. Draw it onto the same picture from Step 1.

First, post the anomaly definition:
> **What counts as unusual here.** An anomaly is any [grain] whose value departs sharply from where its recent trend was heading: a change much larger or smaller than [metric]'s normal [grain]-to-[grain] movement over the prior [W] [grains].

Then draw the chart:

```
/detect-anomaly-viz

chart: anomaly
dataset: ...
aql: <the Step 2 explore, verbatim>
grain: ...
metric label: ...
```

Then post how to read it: the band is the expected range given the recent trend, it widens when movement has been erratic, and the red columns mark what broke out.

### Step 4: Read the result honestly

A period that was never assessed carries `is_anomaly = 0` exactly like one that was assessed and found normal, and the lead-in buckets sit in the result set alongside real findings. Both read as "normal" unless checked for.

Classify every bucket in the reporting window, **in this order**:
1. **Not assessed.** `z_score` is null: a lead-in bucket without a full window of prior history. `is_anomaly` is `0` for these too, so testing it first misreports them as normal.
2. **Unusual.** `z_score` non-null and `is_anomaly = 1`.
3. **Normal.** `z_score` non-null and `is_anomaly = 0`.

Then check, and write the summary (Output → *Summary*):
- **Only buckets inside the reporting timeframe are reported.** The lead-in buckets are context, never findings.
- **`W` and `k` are the values from `detect-anomaly-aql`**, never adjusted for this series.
- **The anomaly chart was drawn**, including when nothing was flagged, or the fallback was taken and said so.
- **No causal or dimensional claim** anywhere in the prose.
- **Numbers formatted** per Conventions → *Numeric formatting*.

Two patterns in the flagged set change what the summary can claim. Check both:
- **Flags sharing a calendar position** (the same month each year, the same weekday). The method has no seasonal term, so a recurring peak flags as an anomaly. Say so, and offer the seasonality-aware re-run.
- **Two flags within `W` buckets of each other.** The first widens the band for the periods after it, so the second was judged against a looser threshold and anything following it may have been missed.

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
- **Nothing flagged**: draw the chart anyway, then say so and name the period. *"No unusual values in GMV over Jul 2023 to Aug 2024; every month moved in line with its recent trend."*
- **A date was named**: lead with the verdict on that bucket, unusual, normal, or not assessed for want of history, then the same list. The full series is still scanned.
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
- The timeframe resolved here is the **reporting** window. `detect-anomaly-aql` opens the filter earlier to supply the lead-in; those buckets are context on both charts and are never reported as findings.

## Conventions
- **On an error, retry once, then fall back.** Step 2: surface the error, never imply detection completed. Step 3: fall back to the Step 2 table plus prose. Never loop more than one retry per step.
- **Titles.** `execute_aql` / `execute_viz` require a `title` (under ~60 chars; avoid "query 1"/"untitled"): Step 1 series chart → `<metric> by <grain> (<reporting timeframe>)`; Step 2 anomaly results → `<metric> anomaly results (<reporting timeframe>)`; Step 3 anomaly chart → `Anomaly detection: <metric> (<reporting timeframe>)`.

### Numeric formatting
- Currency-like measures (label/name contains `revenue`, `cost`, `price`, `arr`, `mrr`, `gmv`, `amount`): `$` prefix, short suffix (`$500K`, `$1.2M`); use the dataset's stated currency symbol if metadata provides it.
- Counts and rates: thousands separators (`1,234`); rates to two significant decimals (`3.42%`).
- z-scores / multiples: one decimal place (`3.4`).

### Out of scope
This skill says which points broke from the trend. It does not say why, and it does not attribute a break to a segment.
- **"Why did this happen?" / "What dimension drove it?"** Reply: "I can flag which points broke from the trend, but identifying which dimension drove an anomaly, or its business cause, is outside this skill. Break the metric down by relevant dimensions in a dashboard, or check your marketing calendar / CRM / news for that window."
- **A per-segment run.** Out of scope: one slice per analysis. Offer a separate run on the segment the user names.
- **"Show the raw numbers."** Show the `execute_aql` anomaly results directly: `bucket`, `actual`, `expected`, `lower_bound`, `upper_bound`, `z_score`, `is_anomaly`. Never group or pivot rows by `is_anomaly`.
