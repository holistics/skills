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
4. **Period covered:** The timeframe named in the Step 1 update and the titles. Earlier data provides necessary baseline context, and is still drawn on the chart.
5. **Focus date:** The selected point's date. The entire series is always scanned, but this date determines the summary's opening focus.

State the specification back in a single sentence using real dates to confirm accuracy.

## What a bare minimum output looks like

* **The anomaly chart (Step 3):** Required output via `detect-anomaly-viz`. The run must provide it or state why it failed.
* **The prose summary (Step 4):** The verdict on the selected bucket, the reason when an edge case applies to it, and one line naming any other flagged buckets.
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

The summary answers the user's question: is the selected bucket unusual? It has three parts, in this order, and nothing after them.

**1. The verdict.** One bold sentence on the selected bucket, followed by its numbers. Take it from that bucket's `verdict`. Do not infer it from `z_score` or `anomaly_flag`.

| `verdict` | Verdict sentence | Followed by |
| --- | --- | --- |
| `unusual` | **Aug 2026 is unusual.** | `actual`, the direction, the expected range (`lower_bound` to `upper_bound`), and `z_score` as a multiple: "GMV was $2.3M, below the expected range of $2.5M to $2.7M (about 7.0× its normal monthly movement)." |
| `normal` | **Jun 2026 is within the expected range.** | `actual` and the expected range: "GMV was $2.1M; the expected range was $1.9M to $2.2M." |
| `not assessed` | **Can't judge Feb 2026.** | Nothing. The reason follows in part 2. |

A bucket still in progress is always **Can't judge**, whatever its `verdict` says.

**2. The reason, when an edge case applies.** When any of these is true for the selected bucket, add up to two of them, most relevant first. Use the wording below with the real dates and values. Add nothing when none applies.

| When | Say |
| --- | --- |
| It is one of the first three buckets of the series. | "GMV starts in Jan 2026, and the check needs 3 earlier months before it can judge one." |
| Its `lower_bound` equals its `upper_bound`: the metric did not move. | "GMV was exactly $40K every month, so there is no movement to compare against." |
| It is still in progress. | "Sep 2026 has 11 of 30 days so far, so its value isn't comparable yet." |
| The bucket before it is missing. | "Mar and Apr 2026 have no data, so this compares May with Feb: three months of change counted as one." |
| It is `unusual`, and the bucket before it is `unusual` in the opposite direction. | "This is GMV returning after the Nov 2025 spike, not a separate event." |
| It is `normal`, and `abs(z_score)` is at least `k` − 1. | "It is 2.8× its normal movement, just under the 3× cut-off." If an earlier bucket is `unusual`, add: "The range is wider than usual because of the Nov 2025 spike." |
| It is judged with fewer than 6 earlier buckets behind it. | "Only 4 earlier months back this, so the expected range is still rough and small moves can stand out." |
| Another bucket at the same calendar position (same month of the year, quarter, or weekday) is `unusual`. | "Dec 2023 and Dec 2024 were also flagged; this may be a yearly pattern the check doesn't account for." |

**3. Other flags.** One line naming every other `unusual` bucket in the results, earliest first, so every red column on the chart is accounted for: "The chart also flags Dec 2023, Jan 2024 and Dec 2024." Name up to five, then "and N more". Leave the line out when there are none. Give no values or multiples for these unless the user asks.

Before writing, check:

* `k` is the default from `detect-anomaly-aql`, unless the user asked for a different threshold.
* The anomaly chart was drawn, or the fallback was taken and said so.
* No causal or dimensional claims. Numbers follow *Numeric formatting*.

## Output

### Summary (prose, Step 4)

Three complete summaries. The Step 3 definition and chart render above each one.

An unusual bucket with a reason and another flag:

> **Dec 2025 is unusual.** GMV was $2.2M, below the expected range of $2.3M to $3.2M (about 3.4× its normal monthly movement).
>
> This is GMV returning after the Nov 2025 spike, not a separate event.
>
> The chart also flags Nov 2025.

A normal bucket close to the cut-off:

> **Apr 2026 is within the expected range.** GMV was $2.0M; the expected range was $1.9M to $3.1M.
>
> It is 2.8× its normal movement, just under the 3× cut-off. The range is wider than usual because of the Nov 2025 spike.
>
> The chart also flags Nov 2025 and Dec 2025.

A bucket that can't be judged:

> **Can't judge Feb 2026.** GMV starts in Jan 2026, and the check needs 3 earlier months before it can judge one.

* **Register:** Professional and plain. Avoid raw notation (no "σ", "z = 3.4"). Express `z` as a spoken multiple.
* **Formatting:** Bold only the verdict sentence. Each part is its own short paragraph. No headings, lists, or tables.
* **No closing offers:** No "what this does not tell you" pointer and no re-run offer. `analyze-changes` offers the next steps after this summary.
* **Different threshold:** If the user asks for a stricter or looser threshold, re-run Steps 2 to 4 with the new `k` (values in `detect-anomaly-aql`).

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
* **Expected range:** Use enough precision that the value and both ends of the range read differently (`$1.68M`, `$1.61M to $1.64M`, not `$1.7M`, `$1.6M to $1.6M`). For a metric that can't go negative, start the range at `0`.

### Out of scope

* **Causation/Attribution:** Do not explain why a break occurred or which dimension drove it. Recommend the user break down the metric in a dashboard or check external calendars.
* **Multiple series:** Analyze only the single series selected by the user.
* **Raw data:** Only display the raw `execute_aql` table (`bucket`, `actual`, `expected`, `lower_bound`, `upper_bound`, `z_score`, `verdict`) if explicitly requested. Drop `anomaly_flag`.
