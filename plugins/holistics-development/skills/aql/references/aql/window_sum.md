## Definition
A window aggregation function that returns the sum of rows in a range relative to the current row.

**Syntax**
```aml
window_sum(agg_expr)
window_sum(agg_expr, order: order_expr, ...)
window_sum(agg_expr, range, order: order_expr, ...)
window_sum(agg_expr, range, order: order_expr, ..., reset: partition_expr, ...)
window_sum(agg_expr, range, order: order_expr, ..., partition: partition_expr, ...)
```

```aml title="Examples"
window_sum(count(users.id))
window_sum(count(users.id), order: count(users.id) | desc())
window_sum(count(users.id), -2..2, order: users.created_at | month())
window_sum(count(users.id), order: users.created_at | month(), reset: users.gender)

// Axis-aware examples
window_sum(revenue, order: 'rows')                        // Running sum across rows
window_sum(revenue, order: 'columns', partition: 'rows')  // Running sum within each row
window_sum(revenue, order: 'x_axis' | desc())             // Running sum in reverse row order
window_sum(revenue, order: 'legend', partition: 'x_axis') // Running sum within each column
```


**Input**
- `agg_expr` (**required**): An aggregation expression to be summed.
- `range` (**optional**): A range of rows to include in the sum. Negative values indicate rows before the current row, and positive values indicate rows after the current row, while 0 indicates the current row. If the beginning or end of the range is not specified, the range will include all rows from the beginning or end of the table. By default, if the range is not specified:
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

The sum of the current row and the rows within the specified range.

## Sample Usages {#sample-usages}

import SampleCode from '@site/src/components/SampleCode'

import { example1 } from './window_sum.js'

<SampleCode title="Running Sum of Count over Order Status" rawResult={example1} />

Notice that it automatically resets the sum when the gender changes. This is because we only specify `order` and thus `reset` defaults to `gender`. If you want it to not reset, you can order by both `gender` and `status`.

import { example2 } from './window_sum.js'

<SampleCode title="Running Sum of Count over Gender and Order Status" rawResult={example2} />

By default, the range is `..0` (from the first row to the current row). Thus if we want to sum all rows, we can use `..` for the range. And since we are not using relative range, we can omit the `order:` parameter.

import { example3 } from './window_sum.js'

<SampleCode title="Total Count of Users with percentage" rawResult={example3} />

### Axis-Aware Usage

You can use axis references to create running totals that adapt to your visualization structure:

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

    // Running total across quarters for each status
    running_by_quarter: window_sum(order_count, order: 'rows'),

    // Running total across statuses for each quarter
    running_by_status: window_sum(order_count, order: 'columns'),

    // Override visualization sort order
    running_reverse: window_sum(order_count, order: 'x_axis' | desc())
  }
}
```

This approach is particularly useful when:
- Your visualization structure might change dynamically
- You want calculations to automatically adapt to different groupings
- You need to respect the visualization's sort order

## See also

- [`window_avg()`](/reference/aql/window_avg)
- [`window_count()`](/reference/aql/window_count)
- [Aggregator Functions](/reference/aql/aggregator-functions): non-windowed equivalents
- [Window Functions](/reference/aql/window-function)
