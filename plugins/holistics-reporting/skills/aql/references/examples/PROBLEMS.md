# Problem types

How to frame the analytical problem — the interpretation the query must recognize.

* `simple_listing` — List rows; no aggregation.
* `top_n` — Top/bottom N items by some metric, globally.
* `top_n_per_group` — Top N within each category (partitioned).
* `top_n_filtered` — Top N among a subset (e.g. 'top users among London').
* `ratio_percentage` — Share / percentage / proportion of total.
* `period_compare` — Compare same metric across periods (YoY, MoM, etc.).
* `cumulative` — Running total / cumulative metric over time.
* `growth_rate` — Change between consecutive periods.
* `cohort_retention` — Cohort retention / cohort-month analysis.
* `filter_on_aggregate` — Entities meeting an aggregate threshold (HAVING-style).
* `nested_aggregation` — Aggregate a metric that's been computed at a finer grain (e.g. 'avg users per city per country', 'max total order value per user'). Inner-then-outer aggregation.
* `date_part_filter` — Filter or break down by a date part (day-of-week, hour-of-day, quarter, etc.).
* `inline_data_inference` — Question requires inferring/deriving new values inline from existing fields (e.g. summarize, classify, extract, similarity, complete).
* `role_playing_relation` — Self-referential / parent-child relationship.
* `combine_metric_and_dim` — Calc mixing a dimension with a measure/metric (revenue = price - discount style).
* `data_type_mismatch` — The field's stored type doesn't fit what the question needs (e.g., numeric comparison/sort on a text-typed field; date math on a string).
* `multi_model_dim` — Question requires a dimension combining dimensions from multiple models.
* `multi_model_metric` — Question requires a metric computed from fields across multiple models.
* `arithmetics` — Question requires arithmetic computation between fields (e.g. `a - b`, `a * b`, `a / b`).
* `nth_per_group` — Get the Nth member's value per group (e.g. third order date per user, first review per author).
* `time_gap_analysis` — Analyze time gaps between consecutive events per entity (e.g. average days between reviews, time since last purchase).
