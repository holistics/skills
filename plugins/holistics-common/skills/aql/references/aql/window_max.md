:::tip Knowledge Checkpoint
Readings that will help you understand this documentation better:
- [Window Functions Overview](/reference/aql/window-function)
:::

## Definition
A window aggregation function that returns the max of rows in a range relative to the current row.

**Syntax**
```aml
window_max(agg_expr)
window_max(agg_expr, order: order_expr, ...)
window_max(agg_expr, range, order: order_expr, ...)
window_max(agg_expr, range, order: order_expr, ..., reset: partition_expr, ...)
window_max(agg_expr, range, order: order_expr, ..., partition: partition_expr, ...)
```

```aml title="Examples"
window_max(count(users.id))
window_max(count(users.id), order: count(users.id) | desc())
window_max(count(users.id), -2..2, order: users.created_at | month())
window_max(count(users.id), order: users.created_at | month(), reset: users.gender)

// Axis-aware examples
window_max(revenue, order: 'rows')                          // Running max across rows
window_max(revenue, order: 'columns', partition: 'rows')    // Running max within each row
window_max(revenue, order: 'x_axis' | desc())               // Running max in reverse row order
window_max(revenue, order: 'legend', partition: 'x_axis')   // Running max within each column
```


**Input**
- `agg_expr` (**required**): An aggregation expression that we want to find max of.
- `range` (**optional**): A range of rows to include in the max. Negative values indicate rows before the current row, and positive values indicate rows after the current row, while 0 indicates the current row. If the beginning or end of the range is not specified, the range will include all rows from the beginning or end of the table. By default, if the range is not specified:
  - If `order` is specified, the range is `..0` (from the first row to the current row).
  - If `order` is not specified, the range is `..` (from the first row to the last row).
- `order` (**required**, **repeatable**): A field that is used for ordering. The order defaults to ascending. The order can be set explicitly with `asc()` or `desc()`. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions):
  - `'rows'` or `'x_axis'`: Order by dimensions mapped to rows/x-axis
  - `'columns'` or `'legend'`: Order by dimensions mapped to columns/legend
  - Axis references can be modified with `asc()` or `desc()`: `order: 'rows' | desc()`
  :::warning
  If the specified order does not uniquely identify rows, the result of the function can be non-deterministic. For example, if you use `order: users.age`, and there are multiple users with the same age in the same partition, the result can be unexpected.
  :::
- `partition` or `reset` (**repeatable**, **optional**): A field that is used for partitioning the table. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions) like `'rows'`, `'columns'`, `'x_axis'`, or `'legend'`. If partitions are not specified:
  - If `order` is specified, the table will be partitioned by all other grouping columns.
  - If `order` is not specified, the table will be considered as a single partition.

**Output**

The max of the current row and the rows within the specified range.

## Sample Usages

Refer to the sample usages in [window_sum](/reference/aql/window_sum#sample-usages).

## See also

- [`window_min()`](/reference/aql/window_min)
- [`window_avg()`](/reference/aql/window_avg)
- [Aggregator Functions](/reference/aql/aggregator-functions)
- [Window Functions](/reference/aql/window-function)
