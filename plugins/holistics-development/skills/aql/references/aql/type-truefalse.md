## Definition
A boolean value, represented as either "true" or "false". This is commonly used to represent logical values. For example, it can be used to represent the result of a comparison, the status of a switch, or the answer to a yes/no question. The "truefalse" type can only take on two values: "true" or "false".

```aml 
dimension is_order_shipped {
  label: "Is Shipped"
  type: "truefalse"
}
```

## Truefalse Operator 
| Operator | Example | Description |
| --- | --- | --- 
| `is` | `orders.is_paid is true` | Equal to |
| `is_not` | `orders.is_paid is not true` | Not equal to|
| `is null` | `orders.is_paid is null` | Include if null |
| `not null` | `orders.is_paid not null` | Include if is not null |
