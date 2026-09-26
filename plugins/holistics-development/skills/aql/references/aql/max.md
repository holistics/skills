## Description

Calculate the greatest value in a column, not including NULL values.

## Syntax

```aql
table | max(column)
```

### Input
* `table`: Source Table
* `column`: A column expression on the given table

### Output
`Scalar`

### Examples
```aql
products | max(products.price)
products | max(products.price * 0.8)
```
