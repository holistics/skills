## Definition
A numeric value, represented as an numeric, integer, float, or double. It can be used as dimension or measure type. The `number` type can include positive and negative values, as well as decimal points.

```aml 
dimension order_value {
  label: "Order Value"
  type: "number"
}

measure revenue {
  label: "Revenue"
  type: "number"
}
```


## Number Operator 
| Operator | Example | Description |
| --- | --- | --- |
| `==` <br /> <br /> `is`| `order_items.discount == 0.5`<br /> <br />  `order_items.discount is 0.5`| Equal to|
| `!=`<br /> <br /> `is not`| `order_items.discount != 1`<br /> <br /> `order_items.discount is not 1`| Not equal to| 
| `>` | `order_items.discount > 0.5` | Greater than | 
| `<` | `order_items.discount < 0.5` | Less than | 
| `is null` | `order_items.discount is null` | Include if null |
| `not null` | `order_items.discount not null` | Include if not null |

## Number Format
For the number formating in the dimension/measure defintion, please refer to [AML Number Format](/reference/aml/number-format)
