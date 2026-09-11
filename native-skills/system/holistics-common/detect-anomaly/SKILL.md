---
name: detect-anomaly
description: |-
  Detect statistical anomalies across a metric's history and visualize them: unusual spikes, drops, and deviations flagged against an expected range built from the metric's own baseline.

  Use when the user searches for unusual values in a metric (trigger words: anomaly, unusual, spike, drop, dip, outlier, "out of the ordinary", "anything weird"). A specific date is optional; the skill always scans the entire series.

  Typical phrasings: detect anomalies in revenue, any outliers in daily signups, has anything looked unusual in MRR lately, were there spikes or drops in active users this quarter, is revenue on May 20 unusual, or /detect_anomaly with no args (the skill asks for the metric).

  Do NOT trigger for: dimensional attribution (which segment drove an anomaly), root cause analysis, or scheduled monitoring. This skill identifies statistically unusual points; it does not explain why they occurred.
user-invocable: false
---

This skill builds an expected band from a metric's history, flags data points that break out of it, and charts the result. It identifies *which* points are unusual, not *why* they moved. Two sub-skills drive the execution: **`detect-anomaly-aql`** owns the methodology and query, and **`detect-anomaly-viz`** owns the chart.

## What a good input looks like

Anomaly detection requires sufficient historical data to establish a baseline. A fully specified task requires five elements, read directly from the user's selected chart point:

1. **Measure and dataset:** The method compares a series against itself, requiring exactly one measure.
2. **Date field and grain:** Day, week, month, or quarter. The grain defines detection resolution (e.g., a two-day spike vanishes in monthly buckets).
3. **Data slice:** The chart's filters plus the specific dimension series selected. One region collapsing can leave the company total flat; one series is analyzed per run.
4. **Period covered:** Flagged buckets are only reported within this timeframe. Earlier data provides necessary baseline context.
5. **Focus date:** The selected point's date. The entire series is always scanned, but this date determines the summary's opening focus.

State the specification back in a single sentence using real dates to confirm accuracy.

## What a bare minimum output looks like

* **The anomaly chart (Step 3):** Required output via `detect-anomaly-viz`. The run must provide it or state why it failed.
* **The prose summary (Step 4):** A business-friendly explanation of the anomaly definition, followed by flagged buckets listing date, value, direction, and magnitude of deviation.
* **The anomaly results (Step 2):** Kept internal as the summary's source of truth. Do not display as a table unless explicitly requested.

## Workflow

Complete these four steps sequentially. Post updates at the close of each step so the user follows the reasoning in real-time. Do not pause execution.

Placeholders: `M` = measure, `T` = time dimension, `<grain>` = time grain, `k` = sensitivity threshold, `<dataset>` = dataset name, `<metric label>` = readable label.

### Step 1: Establish the series

Extract the metric, grain, slice, and period from the selected point. Post these details immediately using real dates, confirming that the full series is being scanned.

### Step 2: Run the detection

Brief:

```
/detect-anomaly-aql

M: ...
T: ...
grain: ...
k: ...
reporting: ...
filters: ...
```

Delegate this step to a sub-agent to invoke `detect-anomaly-aql` for the query, then run `execute_aql`.

Evaluate the returned rows for conditions that impact the final report:

* **Missing buckets:** Gaps break period-to-period comparisons.
* **In-progress final bucket:** A partial period reads as a false collapse. Exclude or flag it.
* **Row count:** A short series returns as unassessed rather than flagged. State this clearly.
* **Selected bucket's `verdict`:** `not assessed` means the run cannot evaluate the specific focus date.

Post the baseline rule naming `k`, along with any flags from these four checks.

### Step 3: Draw the anomaly chart

Brief:

```
/detect-anomaly-viz

dataset: ...
aql: <Step 2 explore, verbatim>
grain: ...
metric label: ...
```

Delegate to a sub-agent to invoke `detect-anomaly-viz` and run `generate_viz`. Draw the chart even if no anomalies are flagged; without the expected band, the user cannot verify a "nothing unusual" claim.

Post the definition of an anomaly so it accompanies the chart:

> **What counts as unusual here.** An anomaly is any [grain] whose value departs sharply from the expected trend: a change significantly larger or smaller than [metric]'s normal [grain]-to-[grain] historical movement.

Briefly explain that the band represents the expected range, it widens during erratic movement, and red columns mark breakouts.

### Step 4: Write the summary

Base the summary strictly on the `verdict` field. Do not infer status from `z_score` or `anomaly_flag`.

| `verdict` | Definition |
| --- | --- |
| `unusual` | A statistically significant finding to list in the summary. |
| `normal` | Assessed; aligned with historical trend. |
| `not assessed` | Insufficient history or variation to judge. |

Write a summary covering only the assessed span. Verify that `k` is unadjusted from Step 2, the chart was drawn (or fallback explained), and no causal claims are made.

Address two specific patterns if present:

* **Recurring calendar positions:** The method lacks seasonal awareness. If anomalies repeat annually/weekly, state this and offer a seasonality-aware re-run.
* **Early flags:** An early unusual value permanently widens the baseline band. Warn the user that milder subsequent anomalies may have been masked by this widened threshold.

## Output

### Summary (prose, Step 4)

> ⟦ Step 3 anomaly definition post_update renders here ⟧
>
> ⟦ Step 3 anomaly chart renders here ⟧
>
> **Found 2 unusual months in GMV, Jul 2023 to Aug 2024:**
>
> * **Nov 2023: $4.2M.** Above the expected trend by about 3.6× its normal monthly movement.
> * **Mar 2024: $1.9M.** Below the expected trend by about 4.1× its normal monthly movement.
>
> **What this does not tell you.** Why they moved, and which segment drove them, is outside this analysis. Break GMV down by product, channel, or customer segment, and check the marketing calendar for those windows.
>
> Want me to re-run with a stricter or looser threshold? Looser flags more months; stricter flags only the most extreme. A seasonality-aware version is also available if GMV has a repeating annual shape.

* **Register:** Professional and plain. Avoid raw notation (no "σ", "z = 3.4"). Express `z` as a spoken multiple.
* **Formatting:** Use bold labels to open sections. Bold the date and value for each finding, followed by plain text. No formal headings or markdown tables for the summary results.
* **Chronological lines:** One line per flagged bucket detailing date, value, direction, and magnitude.
* **Assessed span:** Explicitly name the judged span if it differs from the requested period.
  * *Fully assessed, nothing flagged:* "No unusual values in GMV over Jul 2023 to Aug 2024; every month moved in line with the trend."
  * *Partly assessed:* "Assessed GMV from Jul 2024 onward; earlier months lacked sufficient history."
  * *Nothing assessed:* "Not enough history to assess GMV. The method requires prior movement to establish a baseline."
* **Focus date:** If the selected date falls inside the assessed span, lead with its verdict. If outside, state it cannot be judged before listing the rest.
* **Re-run offer:** Always close with an offer to adjust `k` if findings are present.

## Resolving the spec

Produce one spec `{ dataset, M, T, granularity, filters, timeframe, focus date }` directly from the chart's Viz AML and selected point.

| Field | Source |
| --- | --- |
| `dataset` | Viz `dataset:` property. |
| `M` | Measure belonging to the selected point (`@aql` formula inlined as `metric M = <formula>;`). |
| `T` + `granularity` | X-axis field and its `transformation`. Must be a date axis. |
| `filters` | Chart conditions (excluding time-range) plus the selected legend value if split by dimension. |
| `timeframe` | Chart's time-range filter, or default by grain (day→90d, week→26w, month→24m, quarter→12q). |
| focus date | Selected point's x-axis bucket. |

## Conventions

* **Errors:** Retry once per step, then fall back. Never loop more than once. Surface errors clearly.
* **Titles:** `execute_aql` title → `<metric> anomaly results (<reporting timeframe>)`. `execute_viz` title → `Anomaly detection: <metric> (<reporting timeframe>)`.

### Numeric formatting

* **Currency:** Prefix with `$` and use short suffixes (`$500K`, `$1.2M`). Use the dataset's native currency symbol if available.
* **Counts/Rates:** Use thousands separators (`1,234`). Round rates to two decimals (`3.42%`).
* **Multiples:** Round z-scores to one decimal place (`3.4`).

### Out of scope

* **Causation/Attribution:** Do not explain why a break occurred or which dimension drove it. Recommend the user break down the metric in a dashboard or check external calendars.
* **Multiple series:** Analyze only the single series selected by the user.
* **Raw data:** Only display the raw `execute_aql` table (`bucket`, `actual`, `expected`, `lower_bound`, `upper_bound`, `z_score`, `verdict`) if explicitly requested. Drop `anomaly_flag`.
