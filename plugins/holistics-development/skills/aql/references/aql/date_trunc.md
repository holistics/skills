## Description

Truncate a date or datetime model dimension to the given datetime part.

## Syntax

```aql
date_trunc(model.dimension, datetime_part)

// shorthand
model.dimension | datetime_part()
```

### Input
* `model.dimension`: A **date** or **datetime** model dimension
* `datetime_part`:
  * `day`: The day in the Gregorian calendar year of the dimension value
  * `week`: The first day of the week of the dimension value
  * `month`: The first day of the month of the dimension value
  * `quarter`: The first day of the quarter of the dimension value
  * `year`: The first day of the year of the dimension value
  * `hour`: The first hour in the day of the dimension value
  * `minute`: The minute in the hour of the dimension value

### Output
`Scalar(date)` or `Scalar(datetime)`

### Examples
```aql
date_trunc(orders.created_at, 'year')
orders.created_at | year()
orders.created_at | month()
orders.created_at | quarter()
orders.created_at | week()
orders.created_at | day()
orders.created_at | hour()
orders.created_at | minute()
```
