## Description

Counts the number of non-null values on a column expression in a table.

## Syntax

```aql
table | count(column)
```

### Input
* `table`: Source Table
* `column`: A column expression on the given table

### Output
`Scalar(number)`

### Examples
```aql
orders | count(orders.id)
cities | count(orders.id)
```
