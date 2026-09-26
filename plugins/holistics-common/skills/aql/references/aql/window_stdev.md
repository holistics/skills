:::tip Knowledge Checkpoint
Readings that will help you understand this documentation better:
- [Window Functions Overview](/reference/aql/window-function)
:::

## Definition
A window aggregation function that returns the (sample) standard deviation of rows in a range relative to the current row.

**Syntax**
```aml
window_stdev(agg_expr)
window_stdev(agg_expr, order: order_expr, ...)
window_stdev(agg_expr, range, order: order_expr, ...)
window_stdev(agg_expr, range, order: order_expr, ..., reset: partition_expr, ...)
window_stdev(agg_expr, range, order: order_expr, ..., partition: partition_expr, ...)
```

```aml title="Examples"
window_stdev(count(users.id))
window_stdev(count(users.id), order: count(users.id) | desc())
window_stdev(count(users.id), -2..2, order: users.created_at | month())
window_stdev(count(users.id), order: users.created_at | month(), reset: users.gender)

// Axis-aware examples
window_stdev(revenue, order: 'rows')                          // Running standard deviation across rows
window_stdev(revenue, order: 'columns', partition: 'rows')    // Running standard deviation within each row
window_stdev(revenue, order: 'x_axis' | desc())               // Running standard deviation in reverse row order
window_stdev(revenue, order: 'legend', partition: 'x_axis')   // Running standard deviation within each column
```


**Input**
- `agg_expr` (**required**): An aggregation expression that we want to find the (sample) standard deviation of.
- `range` (**optional**): A range of rows to include in the (sample) standard deviation. Negative values indicate rows before the current row, and positive values indicate rows after the current row, while 0 indicates the current row. If the beginning or end of the range is not specified, the range will include all rows from the beginning or end of the table. By default, if the range is not specified:
  - If `order` is specified, the range is `..0` (from the first row to the current row).
  - If `order` is not specified, the range is `..` (from the first row to the last row).
- `order` (**required**, **repeatable**): A field that is used for ordering. The order defaults to ascending. The order can be set explicitly with `asc()` or `desc()`.

  You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions):
  - `'rows'` or `'x_axis'`: Order by row position in the visualization
  - `'columns'` or `'legend'`: Order by column position in the visualization

  Axis references can be modified with `asc()` or `desc()`: `order: 'rows' | desc()`

  :::warning
  If the specified order does not uniquely identify rows, the result of the function can be non-deterministic. For example, if you use `order: users.age`, and there are multiple users with the same age in the same partition, the result can be unexpected.
  :::
- `partition` or `reset` (**repeatable**, **optional**): A field that is used for partitioning the table. You can also use [axis references](/reference/aql/window-function#axis-aware-window-functions) like `'rows'`, `'columns'`, `'x_axis'`, or `'legend'`. If partitions are not specified:
  - If `order` is specified, the table will be partitioned by all other grouping columns.
  - If `order` is not specified, the table will be considered as a single partition.

**Output**

The (sample) standard deviation of the current row and the rows within the specified range.

## Sample Usages {#sample-usages}

The most common use case for `window_stdev` is to draw a Process Behavior Chart (PBC) for a process. The PBC is a type of control chart that shows the process variation over time. The `window_stdev` function can be used to calculate the standard deviation of a process variable over a range of time periods. This can help you identify when the process is out of control and needs to be adjusted.

Here is an example of how you can use `window_stdev` to create an PBC in Holistics:

<img src="https://cdn.holistics.io/docs/as-code/pbc.png" alt="pbc" width="1363" height="988"/>

import SampleCode from '@site/src/components/SampleCode'

import { example1 } from './window_stdev.js'

<SampleCode title="Process Behavior Chart AQL" rawResult={example1} />

## See also

- [`window_stdevp()`](/reference/aql/window_stdevp)
- [`window_var()`](/reference/aql/window_var)
- [Window Functions](/reference/aql/window-function)
