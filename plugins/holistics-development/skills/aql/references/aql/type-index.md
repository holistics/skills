**Type** can be understood as the “blueprint”, or the “category” of an object in AQL. Depending on its type, an object can have certain properties.

For example, considering the following model:

```aml
Model orders {
  dimension id {type: 'number'}
  dimension total_value {type: 'number'}
  dimension status {type: 'text'}

  measure orders_count {
    type: 'number'
    description: 'Count all orders, regardless of status'
    definition: @aql count(orders.id) ;;
  }
}
```

- `orders` is an object of type `Model`
- `total_value` is an object of type `Field`, with the following properties:
    - Field class: Dimension
    - Origin model: `orders`
    - Data type: `number`
- `orders_count` is an object of type `Field`, with the following properties:
    - Field class: Measure
    - Origin model: `orders`
    - Data type: `number`

In this section of the docs, you will find detailed information about different types available in AQL.
