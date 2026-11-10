## Description
Calculates a metric within a custom period, it can be used to compare how a metric performs in a specific period compared to another period.

## Syntax

```aql
metric | exact_period(metric, time_dimension, time_range)
```

### Input
- `metric`: A metric that you want to calculate within a custom period
- `time_dimension`: A pre-defined datetime/date dimension that is used for shifting
- `time_range`: A datetime literal that specifies an exact time range for shifting. E.g. `@(2022-04-01)`, `@(2022)`, `@(last 2 weeks)`

### Output
`Scalar`

### Examples
```aql
orders | count(orders.id) | exact_period(orders.created_at, @(2022-07-01 - 2022-09-01))
```
