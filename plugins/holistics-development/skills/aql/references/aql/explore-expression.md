Explore expressions are expressions that represent a Holistics [Explore](/docs/data-exploration).

Explore Expressions are designed to be used as an **intermediate representation of the Explore**, which can be used to generate the final SQL query to be executed. When a user drag-and-drops dimensions and/or measures into the Explore, Holistics will generate an Explore expression and then use it to generate the final SQL query.


### Structure
```aml
explore {
  dimensions {
    dimension1,
    dimension2
    ...
  }
  measures {
    measure1,
    measure_name2: measure2 // you can also specify a custom name for the measure
    ...
  }
  filters { //optional
    logical_expression1,
    logical_expression2
    ...
  }
  relationships { // optional
    relationship1,
    relationship2
    ...
  }
}
```

### Explore vs Table Expressions
You can think of an Explore expression as a semi-automated version of a Table expression. The key difference is the fact that the Explore expression will automatically choose the right tables to query from based on the dimensions and measures you have defined.

For example, given the following Explore expression:
```aml
explore {
  dimensions {
    users.name
  }
  measures {
    count_orders: count(orders.id)
  }
}
```
It is equivalent to the following Table expression:
```aml
orders
| group(users.name)
| select(users.name, count_orders: count(orders.id))
```

Notice that in the Table expression, we have to manually specify the `orders` table to query from. In the Explore expression, you don't have to do that as Holistics will automatically choose the right tables to query from based on the dimensions and measures you have chosen.

### Examples

```aml
explore {
  dimensions {
    merchants.name
  }

  measures {
    count_merchants_products: count(products.id)
      | with_relationships(products.merchant_id > merchants.id),
    count_products_bought: count(products.id)
  }

  filters {
    merchants.name == "John"
  }
}
```
