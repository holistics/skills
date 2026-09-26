Metric functions transform an input metric expression into another metric expression, usually by modifying the [context](/as-code/aql/learn/metric-context) that the input is evaluated in: its filters, its relationships, its level of detail, or its time window.

They split into five categories:

| Category | When to reach for it | Functions |
| --- | --- | --- |
| **Condition** | Restrict which rows feed into the metric. | [`where`](/reference/aql/where) |
| **Relationship** | Override the dataset's default joins for a specific metric. | [`with_relationships`](/reference/aql/with_relationships) |
| **Level of Detail** | Force the metric to compute at a specific grain (independent of the report's grouping). | [`of_all`](/reference/aql/of_all), [`keep`](/reference/aql/keep), [`dimensionalize`](/reference/aql/dimensionalize), [`percent_of_total`](/reference/aql/percent_of_total) |
| **Time-based** | Shift, accumulate, or compare across time periods. | [`running_total`](/reference/aql/running_total), [`period_to_date`](/reference/aql/period_to_date), [`exact_period`](/reference/aql/exact_period), [`relative_period`](/reference/aql/relative_period), [`trailing_period`](/reference/aql/trailing_period) |
| **Window** | Rank, navigate to neighboring rows, or aggregate across a moving frame. Analogous to SQL window functions (see the [Window Functions overview](/reference/aql/window-function)). | `rank`, `dense_rank`, `ntile`, `percent_rank`, `first_value`, `last_value`, `nth_value`, `previous`, `next`, `window_sum`, `window_avg`, `window_min`, `window_max`, `window_count`, `window_stdev`, `window_stdevp`, `window_var`, `window_varp` |

## See also

- [Level of Detail](/as-code/aql/learn/level-of-detail): conceptual guide to LoD functions
- [Time Comparisons](/as-code/aql/learn/time-comparisons): conceptual guide to time-based functions
- [Window Functions](/reference/aql/window-function): conceptual + reference for window functions
- [Order of Operations](/as-code/aql/order-of-operations): when each function category fires in the pipeline
