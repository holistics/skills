## Description

Counts the number of values in a table that satisfy a condition, not including NULL values.

## Syntax

```aql
table | count_if(condition)
```

### Input
* `table`: Source Table
* `condition`: A condition on the given table

### Output
`Scalar(number)`

### Examples
```aql
orders | count_if(orders.status == 'success')
orders | count_if(orders.status == 'success' and users.gender == 'm')
orders | count_if(orders.created_at matches @(yesterday))
```
