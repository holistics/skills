---
name: common-analysis
label: Common Analysis
description: |-
  Add a common analysis to a chart's series, such as a trend line, while keeping the series it is computed from.

  Use when the user asks to add an analysis to a chart, on a dashboard or while exploring a chart.

  Typical phrasings: add a trend line, show the trend, fit a regression line.

  Do NOT trigger for building a chart with no analysis on it, or for flagging unusual values (anomaly detection).
user-invocable: false
---

# Common analyses on a chart

An analysis set on a series replaces its raw values. Unless the user wants the analysis alone, keep the raw series and put the analysis on a second copy of the metric.

Build the chart with the usual flow: generate_aql → generate_viz → execute_viz. For a chart in a dashboard, also follow the build-visualizations skill.

## Trend line

Most trend requests keep the raw series; a few want the trend alone. When unsure, ask.

* **Keep the raw series** — "add a trend line", "show the trend on this chart", "is revenue trending up?"
* **Trend alone** — "show only the trend line", "replace the columns with a trend line"

Hard requirements:

1. **Keep the existing raw series** — its metric, display type (column, line, …), and settings.
2. **Alias the metric a second time in the AQL explore** — ask generate_aql for the same metric twice under two names (e.g. `revenue_won` and `revenue_won_trend: revenue_won`). Skip the alias only when the user asks for the trend alone.
3. **Ask generate_viz for two y-axis series** — the raw metric with no analytic, and the alias with `analytic: RegressionLine` (`type: 'linear'` unless the user asks for another fit), displayed as a dashed line. A column raw series with a line trend needs a `CombinationChart`.
4. **Verify before presenting** — after execute_viz, check that the result has both a raw-value column and a fitted-trend column. If one is missing, fix the explore or the `query` and run again.
