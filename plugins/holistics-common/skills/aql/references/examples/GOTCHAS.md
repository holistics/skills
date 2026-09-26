# Gotchas

Pitfalls to avoid. `[silent]` = fails with no validation error (wrong-but-valid result); prevent proactively.

* `missing_date_trunc_with_relative_period` `[silent]` — Omitting `date_trunc` (e.g. `| month()`) on the time dim in `explore.dimensions` when also using `relative_period`. The time dim MUST be date-trunc'd.
* `rank_on_dim_not_metric` — Passing a dimension as `rank()`'s `order:` argument. The argument must be a metric — aggregate the dim first (e.g. `model | max(model.dim)`).
* `unaggregated_dim_in_explore_measures` — Placing an unaggregated dimension inside `explore.measures`. Only metrics belong there — aggregate the dim into a metric first, or move it to `explore.dimensions`.
* `combine_unaggregated_dim_with_metric` — Combining a dimension with a metric in arithmetic/string ops without aggregating the dim first. Aggregate the dim (e.g. `model | max(model.dim)`) to coerce it into a metric, then combine.
* `missing_pipe_precedence_parens` `[silent]` — Mixing pipe `|` with arithmetic without parenthesizing. Pipe has lower precedence than arithmetic, so `a | f(x) - b` parses as `a | (f(x) - b)`. Parenthesize: `(a | f(x)) - b`.
* `manual_join_attempt` `[silent]` — Trying to implement a join via field equality (e.g. `users.id == orders.user_id` in `explore.filters`). AQL handles joins automatically via pre-defined relationships — never write them yourself.
* `double_aggregating_measures` `[silent]` — Applying an outer aggregation directly on an already-aggregated value (measure/metric), e.g. `model | sum(model.measure)` or `model | avg(metric)`. Use the measure directly (if no re-aggregation needed) or proper nested aggregation `unique(...) | select(...) | outer_agg(...)`.
* `extra_dim_changes_explore_grain` `[silent]` — Including a dim in `explore.dimensions` that breaks the result to a finer grain than the question asks (e.g. adding `users.name` when the question asks per-city). Measures will be wrongly broken down. Include only the dims that match the desired grain.
* `wrong_inner_grain_in_nested_aggregation` `[silent]` — Choosing the wrong dim in `unique(...)` so the inner aggregation runs at the wrong grain. The inner grain must be where the inner metric naturally lives (e.g. count orders per city → `unique(public_cities.id)`, not `unique(countries.name)`).
* `ranking_grain_mismatch` `[silent]` — Ranking at one grain (e.g. `rank(... products.id)`) while the explore aggregates at another (e.g. dim `products.name`). Rank grain and explore grain must match — either include the rank grain in `explore.dimensions`, or change the rank to use the explore's grain.
