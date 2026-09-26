## Description

The `date_part` function extracts a specific numeric part from a date or datetime value. It returns the numeric representation of the specified part of the date.

## Syntax

```aql
date_part(datetime_part, date_or_datetime)
```

### Input
* `datetime_part`:
  * `'year'`: Returns the numeric year (e.g., 2021)
  * `'quarter'`: Returns the quarter number (1-4)
  * `'month'`: Returns the month number (1-12)
  * `'week'`: Returns the week number of the year (1-53)
  * `'dayofweek'` or `'dow'`: Returns the day of the week number (0-6)
  * `'day'`: Returns the day of the month (1-31)
  * `'hour'`: Returns the hour of the day (0-23)
  * `'minute'`: Returns the minute of the hour (0-59)
  * `'second'`: Returns the second of the minute (0-59)
* `date_or_datetime`: A **date** or **datetime** value

### Output
`Scalar(number)`

### Examples
```aql
// orders.created_at -> 2021-05-28 10:30:39
date_part('year', orders.created_at) // -> 2021
date_part('quarter', orders.created_at) // -> 2
date_part('month', orders.created_at) // -> 5
date_part('week', orders.created_at) // -> 21
date_part('dayofweek', orders.created_at) // -> 4
date_part('dow', orders.created_at) // -> 4
date_part('day', orders.created_at) // -> 28
date_part('hour', orders.created_at) // -> 10
date_part('minute', orders.created_at) // -> 30
date_part('second', orders.created_at) // -> 39
```
