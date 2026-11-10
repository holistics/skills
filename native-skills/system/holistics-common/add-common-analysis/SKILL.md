---
name: add-common-analysis
label: Add Common Analysis
description: |-
  Add a common analysis to a chart's series, such as a trend line or a period-over-period comparison, while keeping the series it is computed from.

  Use when the user asks to add an analysis to a chart, on a dashboard or while exploring a chart.

  Typical phrasings: add a trend line, show the trend, fit a regression line, compare with last month, add period-over-period, show change vs same month last year.

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

## Period-over-period (PoP)

A PoP adds, for each metric in the chart, its value in the previous period and the % change, as new metrics next to the raw series. The rest of the chart stays as it is.

The previous-period value is the current period shifted back one period along a date field. So the chart needs:

* **A date field to compare along** — the chart's left-most date field; if the chart has none, the date field of its time condition. If neither exists, ask one question for the date field and grain, listing the best-fitting options first and "Other" last.
* **A time condition on that field** that sets the current period, e.g. "this year". Without it there is no current period to shift. The date does not have to be on the chart.

Do not build the PoP if either of these holds — tell the user why and what to change:

* **Date grain below hour** (minute, second) — ask them to use hour or coarser.
* **Date transform is a time part** (e.g. Quarter of year, Day of week) — ask them to use a date grain such as month instead.

When the user wants viewers to switch the comparison on a dashboard, use a `PopBlock` through the build-dashboard-controls skill instead. If the viz is already wired to a `PopInteraction`, warn that the dashboard comparison also applies to the new PoP series.

Hard requirements:

1. **Keep the chart as it is** — type, x-axis, breakdowns, settings. Do not add the date field as a dimension unless the chart already has it, the user asks, or the viz is a table or pivot table.
2. **Add the time condition if it is missing** — the current period at the date field's grain. Tell the user you added it.
3. **Compare with `relative_period`** — never with filtered metrics or fixed years. Ask generate_aql for two metrics per metric in the chart: a previous-period value and a % change (e.g. `revenue_prev_month` and `revenue_prev_month_pct`). Compare all metrics, not only the first. Skip the absolute change unless the user asks.
4. **Take the period from the user's words** — "last month", "same month last year", "previous 3 months"; "last year vs this year" is the previous 1 year. Pass the phrase to generate_aql as the comparison period; do not rewrite it. With no period given, use the previous 1 period.
5. **Place the series** — ask generate_viz for the raw series and the previous value on the y-axis, in the chart's current display type, and the % change in the tooltip. For a table or pivot table, add the % change as an extra column instead.
6. **Name the series from the comparison** — `Revenue (Previous month)` and `Revenue %Δ (Previous month)`. A period of 1 is singular without the number; more than 1 keeps the number and is plural (`Revenue (Previous 3 months)`).
7. **Verify before presenting** — after execute_viz, check that each metric has a raw, previous-value and % change column, that the time condition is present, and that the chart type and breakdowns are unchanged. If not, fix the explore or the `query` and run again.
