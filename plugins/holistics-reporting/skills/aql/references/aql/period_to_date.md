## Description
Calculates a metric from the beginning of year, quarter, month, etc to the current date. For example, you can apply this computation to determine the total orders you have accumulated in sales from the beginning of the year up until the present date, also known as Year-to-Date(YTD) metric

## Syntax

```aql
metric | period_to_date(date_part, date_dimension)
```

### Input
- `metric` (**required**): The metric being accumulated
- `date_part` (**required**): The time period for which the measure should reset. It can be one of the following options. Can be one of the followings: `'year'`, `'quarter'`, `'month'`, `'week'`, `'day'`
- `date_dimension` (**required**): The date dimension that is used to determine the reset period

### Output
`Scalar`

### Examples
```aql
orders | count(orders.id) | period_to_date('year', orders.created_at) // Return year-to-date total orders
orders | count(orders.id) | period_to_date('month', orders.created_at) // Return month-to-date total orders
```
