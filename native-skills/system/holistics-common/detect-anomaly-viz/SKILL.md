---
name: detect-anomaly-viz
description: |-
  Guidelines for charting detect-anomaly results. ONLY use this skill when explicitly asked to do so.
user-invocable: false
---

This skill generates a single chart during Step 3, displaying the metric series alongside its expected band and flagged anomaly buckets. The chart must span the entire timeframe returned by the Step 2 explore (starting from the earliest data point) to ensure the expected band has sufficient historical data to form properly.

Never hand-write the visualization body. Use `generate_viz` to write it, and `execute_viz` to validate it upon execution. You must state the visual styling explicitly in your `query`, as `generate_viz` will otherwise default to its standard palette and `pattern: 'inherited'`.

This skill is invoked only once, using parameters supplied by the caller.

### Anomaly chart (Step 3)

**Parameters:** `dataset`, `aql` (the Step 2 explore, verbatim), `grain`, `metric label`.

This chart plots the series, the expected band, and the anomaly flags. Because the Step 2 explore already returns every required field, pass its output through completely untouched. Do not apply any additional filters or timeframes.

1. Call `generate_viz` using the exact string below (replace bracketed variables with the parameters):

   `generate_viz(dataset_uname: <dataset>, aql: <the Step 2 explore, verbatim>, query: "Combination chart of <metric label> by <grain>: anomaly_flag as red #FCB8B8 columns on the FIRST y-axis, 0..1 scale; actual as a solid #255DD4 line and lower_bound and upper_bound as grey #9CA3AF dashed lines, all three on the SECOND y-axis; x-axis is the <grain> bucket; format <metric label> as short-suffix currency like $500K; tooltips for expected, <metric label>, and z_score.")`
2. Use the exact visualization output produced by `generate_viz`. Do not manually adjust or edit any part of it.
3. Call `execute_viz` using the generated visualization:

   `execute_viz(dataset_uname: <dataset>, viz: <the viz from generate_viz, unchanged>, title: …)`

**Error Handling:**
If `execute_viz` returns an error, feed the error text back into the `generate_viz` `query` prompt so it can self-correct, and retry exactly once. If it fails a second time, fall back to displaying the Step 2 table alongside a prose explanation. **This is the only permitted scenario where you may omit the anomaly chart.**

### Do not regress

* Pass **only** `dataset_uname`, `viz`, and `title` to `execute_viz`. Do not include an `aql` property.
* Use strict 6-digit hex codes for colors. 8-digit alpha hex codes may be rejected by the system.
* Ensure `anomaly_flag` is assigned to the **first** y-axis (scale 0..1). The actual metric, `lower_bound`, and `upper_bound` must be assigned to the **second** y-axis. This exact order ensures the columns render correctly behind the lines.
* Do not plot `expected` as a line, bar, or point series. It should only appear in the tooltip.
* Only chart the `anomaly_flag` field, never `verdict`. The `verdict` field is purely text-based for prose and cannot be plotted.
* The chart must cover the entire dataset returned by the Step 2 explore. Do not crop the data to a specific reporting window; doing so hides the historical lead-in required to form the band and makes the series appear to start later than the data allows. Do not re-filter the data here, as the explore's initial range dictates how `expected`, `spread`, and `z_score` are computed.
* If the metric cannot physically go negative, clamp the **displayed** lower bound at 0. Because the expected band forms around the trend rather than the absolute level, the mathematical lower bound may occasionally dip below zero.
