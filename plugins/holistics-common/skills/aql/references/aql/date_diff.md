## Description

Calculates the difference between two date or datetime values in the specified `datetime_part`

## Syntax

```aql
date_diff(datetime_part, start, end)
```

### Input
* `start`: The first date or datetime value
* `end`: The second date or datetime value
* `datetime_part`:
  * `'day'`: The number of days between the two values.
  * `'week'`: The number of weeks between the two values.
  * `'month'`: The number of months between the two values.
  * `'quarter'`: The number of quarters between the two values.
  * `'year'`: The number of years between the two values.

### Output
`Scalar(number)`

### Examples
```aql
date_diff('day', orders.created_at, @(now))
date_diff('month', @(2 weeks ago), orders.created_at)
date_diff('month', orders.created_at, orders.updated_at)
```
