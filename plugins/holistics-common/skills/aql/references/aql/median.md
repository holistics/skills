## Description

Calculate the median value in a column expression, not including NULL values.

## Syntax

```aql
table | median(column)
```

### Input
* `table`: Source Table
* `column`: A column expression on the given table

### Output
`Scalar`

### Examples
```aql
products | median(products.price)
```
