## Description

Sums the values in a Number column expression, not including NULL values.

## Syntax

```aql
table | sum(column)
```

### Input
* `table`: Source Table
* `column`: A **number** column expression on the given table

### Output
`Scalar(number)`

### Examples
```aql
products | sum(products.price)
order_items | sum(order_items.quantity * products.price)
```
