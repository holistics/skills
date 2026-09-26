## Description
Calculates a metric over a specific number of date periods up to the current period. For example, you can apply this function to calculate the total orders you have in the last 3 months up until the current month, also known as Trailing 3 Months Metric.

## Syntax

```aql
metric | trailing_period(date_dimension, period)
```

### Input
- `metric` (**required**): The metric on which you want to apply the `trailing_period()` function
- `date_dimension` (**required**): The date dimension that is used to determine the periods
- `period` (**required**): An interval literal that specifies the number of periods to calculate (includes the current period). E.g. `interval(3 months)`, `interval(1 year)`.

### Output
`Scalar`

### Examples
```aql
orders | count(orders.id) | trailing_period(orders.created_at, interval(3 months))
```
