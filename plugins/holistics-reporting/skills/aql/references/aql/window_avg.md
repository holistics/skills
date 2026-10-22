:::tip Knowledge Checkpoint
Readings that will help you understand this documentation better:
- [Window Functions Overview](/reference/aql/window-function)
:::

## Definition
A window aggregation function that returns the average of rows in a range relative to the current row.

**Syntax**
```aml
window_avg(agg_expr)
window_avg(agg_expr, order: order_expr, ...)
window_avg(agg_expr, range, order: order_expr, ...)
window_avg(agg_expr, range, order: order_expr, ..., reset: partition_expr, ...)
window_avg(agg_expr, range, order: order_expr, ..., partition: partition_expr, ...)
```

```aml title="Examples"
window_avg(count(users.id))
window_avg(count(users.id), order: count(users.id) | desc())
window_avg(count(users.id), -2..2, order: users.created_at | month())
window_avg(count(users.id), order: users.created_at | month(), reset: users.gender)

// Axis-aware examples
window_avg(revenue, order: 'rows')                        // Running average across rows
window_avg(revenue, order: 'columns', partition: 'rows')  // Running average within each row
window_avg(revenue, order: 'x_axis' | desc())             // Running average in reverse row order
window_avg(revenue, order: 'legend', partition: 'x_axis') // Running average within each column
```


**Input**
- `agg_expr` (**required**): An aggregation expression to be averaged.
- `range` (**optional**): A range of rows to include in the average. Negative values indicate rows before the current row, and positive values indicate rows after the current row, while 0 indicates the current row. If the beginning or end of the range is not specified, the range will include all rows from the beginning or end of the table. By default, if the range is not specified:
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

The average of the current row and the rows within the specified range.

## Sample Usages

import SampleCode from '@site/src/components/SampleCode'

import { example1 } from './window_avg.js'

<SampleCode title="Avg of Count" rawResult={example1} />

The most common use case for `window_avg` is to calculate the average of a column. In this example, we calculate the average of the count of users.

---

import { example2 } from './window_avg.js'

<SampleCode title="Avg of Count with Moving Average" rawResult={example2} />

We can also use it to calculate the moving average of a column. In this example, we calculate the moving average of the count of users, ordered by the year they were created. Notice that we are using the `range` parameter to specify the range of rows to include in the average. In this case, we are calculating the average of the current row and the two rows before and after it (i.e. a total of 5 rows) with the range `-2..2`.

### Axis-Aware Usage

You can use axis references to create running averages that adapt to your visualization structure:

```aml
explore {
  dimensions {
    rows {
      _quarter: orders.created_at | quarter()
    }
    columns {
      _status: orders.status
    }
  }

  measures {
    order_count: count(orders.id),

    // Running average across quarters for each status
    running_by_quarter: window_avg(order_count, order: 'rows'),

    // Running average across statuses for each quarter
    running_by_status: window_avg(order_count, order: 'columns'),

    // Override visualization sort order
    running_reverse: window_avg(order_count, order: 'x_axis' | desc())
  }
}
```

This approach is particularly useful when:
- Your visualization structure might change dynamically
- You want calculations to automatically adapt to different groupings
- You need to respect the visualization's sort order

## See also

- [`window_sum()`](/reference/aql/window_sum)
- [`window_count()`](/reference/aql/window_count)
- [Aggregator Functions](/reference/aql/aggregator-functions)
- [Window Functions](/reference/aql/window-function)
