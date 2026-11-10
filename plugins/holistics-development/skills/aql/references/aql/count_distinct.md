## Description

Counts the number of distinct values in a column, not including NULL values.

## Syntax

```aql
table | count_distinct(column)
```

### Input
* `table`: Source Table
* `column`: A column expression on the source table

### Output
`Scalar(number)`

### Examples
```aql
orders | count_distinct(orders.status)
```
