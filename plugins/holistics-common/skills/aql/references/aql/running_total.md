## Description
Calculate a running total of a metric along specified dimensions, from the starting of time to the current period.

By default, the running total will be calculated after filtering (`keep_filters: true`). To calculate a running total of all data, ignoring any filter on the running dimensions, you can add a `keep_filters: false` parameter to the function.

## Syntax

```aql
metric | running_total()
metric | running_total(running_dimension, ...)
metric | running_total(running_dimension, ..., keep_filters: false)
```

### Input
- `metric`: The metric that you want to turn into a running measure.
- `running_dimension` (**optional**, **repeatable**): The dimension you want your aggregation to run along. If not specified, the returned measure will run along all dimensions in your explore (`explore.dimensions`)
- `keep_filters:` (**optional**): A boolean value that specifies whether to keep the filters applied on the running dimensions. Default is `true`.

### Output
`Scalar`

### Examples
```aql
orders | count(orders.id) | running_total(orders.created_at)

// with multiple running dimensions
orders | count(orders.id) | running_total(orders.created_at, orders.status)

// with keep_filters: false
orders | count(orders.id) | running_total(orders.created_at, orders.status, keep_filters: false)
```
