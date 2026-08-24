---
name: detect-anomaly-viz
description: |-
  Guidelines for charting detect-anomaly results. ONLY use this skill when explicitly asked to do so.
user-invocable: false
---

One chart, drawn in Step 3: the metric series with its expected band and the flagged buckets. It spans whatever the Step 2 explore returned — the series from its start — so the band has history to form against.

Never hand-write the viz body. `generate_viz` writes it, `execute_viz` validates it on execution. State the decoration explicitly in the `query`, because `generate_viz` defaults its palette and `pattern: 'inherited'` unless told otherwise.

Invoked once. The caller supplies the parameters.

### Anomaly chart (Step 3)

Parameters: `dataset`, `aql` (the Step 2 explore, verbatim), `grain`, `metric label`.

The series, plus the band and the flags. The Step 2 explore already returns every field this chart needs, so it is passed through untouched and no filters or timeframe are supplied again.

1. `generate_viz(dataset_uname: <dataset>, aql: <the Step 2 explore, verbatim>, query: "Combination chart of <metric label> by <grain>: anomaly_flag as red #FCB8B8 columns on the FIRST y-axis, 0..1 scale; actual as a solid #255DD4 line and lower_bound and upper_bound as grey #9CA3AF dashed lines, all three on the SECOND y-axis; x-axis is the <grain> bucket; format <metric label> as short-suffix currency like $500K; tooltips for expected, <metric label>, and z_score.")`
2. Use the viz `generate_viz` produced as-is. Do not adjust anything.
3. `execute_viz(dataset_uname: <dataset>, viz: <the viz from generate_viz, unchanged>, title: …)`

On an error, feed the error text back into `generate_viz`'s `query` (it self-corrects from prior errors) and retry once. If it still fails, fall back to the Step 2 table plus prose. **That is the only permitted reason to ship without this chart.**

### Do not regress
- Pass only `dataset_uname`, `viz`, `title` to `execute_viz`. No `aql` property.
- 6-digit hex only. An 8-digit alpha hex can be rejected.
- `anomaly_flag` goes on the **first** y-axis (0..1) and the metric, `lower_bound` and `upper_bound` on the **second**. That order is what keeps the columns behind the lines.
- Chart `anomaly_flag`, never `verdict`. `verdict` is a text field for the prose; it has no numeric series to plot.
- The chart covers everything the Step 2 explore returned. Cropping to the reporting window hides the lead-in the band needs to form, and shows the series starting later than the results do. Do not re-filter here: the explore's own range is what its `expected`, `spread` and `z_score` were computed against.
- For a metric that cannot go negative, clamp the **displayed** lower bound at 0. The band sits around the trend rather than the level, so it can dip below zero.
