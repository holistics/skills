## Description
Calculates a metric in the **active time-range** shifted by a specified interval. The active time-range can be the time range specified in a filter (if no time dimension is active) or the time period in each row of a time dimension.

## Syntax

```aql
metric | relative_period(time_dimension, time_interval)
```

### Input
- `metric`: A metric that you want to calculate within a relative interval
- `time_dimension`: A pre-defined datetime/date dimension that is used for shifting
- `time_interval`: A relative interval for shifting from the time condition. E.g. `interval(-1 month)`

### Output
`Scalar`

### Examples
```aql
orders | count(orders.id) | relative_period(orders.created_at, interval(-1 month))
```
