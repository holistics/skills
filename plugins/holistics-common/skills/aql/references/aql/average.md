## Description

Calculate the average of values in a Number column expression, not including NULL values. Alias: `avg`

## Syntax

```aql
table | average(column)
table | avg(column)
```

### Input
* `table`: Source Table
* `column`: A **number** column expression

### Output
`Scalar(number)`

### Examples
```aql
products | avg(products.price)
order_items | sum(order_items.quantity * products.price)
```
