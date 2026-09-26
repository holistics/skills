# Techniques

Positive AQL idioms.

* `nested_aggregation` — `unique() | select() | outer_agg()` to aggregate at one grain then another.
* `filter_by_subset` — `field in (metric | select(...))` to filter rows by a metric-derived ID/value set.
* `subset_as_table_metric` — Represent a reusable subset of rows as a Table-shaped metric (not a scalar). For example, these metrics can be used for filter_by_subset or nested_aggregation.
* `subset_by_row_filter` — Build a subset by row-level filtering on a dim: `table_metric | where(dim_condition)`.
* `subset_by_aggregate_filter` — Build a subset of entities qualifying by an aggregate condition: `unique(id) | filter(metric > X)`.
* `fn:rank` — AQL `rank()` function.
* `fn:top` — AQL `top()` / `bottom()` functions.
* `limit_sort` — Top-N via `limit: N` + `sort` (DESC/ASC). Ranking applies to the final explore result, not within a prior calculation. No dense-ranking or partitioning support.
* `fn:running_total` — AQL `running_total()` function.
* `fn:relative_period` — AQL `relative_period()` function.
* `window_navigation` — Navigation window functions (e.g. `previous()`, `next()`, `first_value()`) for prior/next-row values.
* `aggregate_on_window_function` — Aggregate over a metric whose values come from a window function (e.g. `avg()` over rows that reference a `previous()`-based metric).
* `fn:exclude_grains` — AQL `exclude_grains()` function (alias `of_all()`).
* `fn:keep_grains` — AQL `keep_grains()` function.
* `dimensionalize_metric` — `dimensionalize(...)` inside a `dimension` declaration to promote a metric to a dim.
* `fn:date_part` — AQL `date_part()` function.
* `fn:date_diff` — AQL `date_diff(unit, start_date, end_date)` function.
* `fn:cast` — AQL `cast(field, type)` function.
* `custom_dim` — Declare a custom dimension with calculation logic (e.g. `dimension model.x = a - b`).
* `custom_dim_on_many_side` — When declaring a custom dimension that involves multiple models, place it on the many-side model.
* `metric_on_many_side` — When defining a metric that involves multiple models, use the many-side model as the source table (e.g. `items | sum(items.price - orders.discount)`).
* `combine_metric_and_dim` — Dims and metrics can't be combined directly in arithmetic/string ops. Aggregate the dim into a metric first (e.g. `model | max(model.dim)`), then combine.
* `use_existing_measure` — Use an existing measure directly; do NOT re-aggregate.
* `re_aggregate_existing_measure` — Re-aggregate an existing measure only via nested aggregation (unique + select + outer_agg).
* `fn:where` — AQL `where()` function.
* `fn:filter` — AQL `filter()` function.
* `explore_filters` — AQL `explore.filters { ... }` block.
* `ai_functions` — AQL AI functions: `ai_complete`, `ai_classify`, `ai_summarize`, `ai_similarity`. Snowflake/Databricks only.
* `role_playing_via_model` — Filter directly through the role-playing model (e.g. `parent_categories.name == ...`).
* `role_playing_via_lookup` — Last-resort: build an ID metric and use `field in (ids)` when no role-playing model exists.
