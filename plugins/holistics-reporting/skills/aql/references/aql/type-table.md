:::tip Knowledge Checkpoint
This documentation assumes you are somewhat familiar with the following concepts:
- [Types](/as-code/amql/aql-basic-concepts#types)
- [Model](/as-code/amql/aql-basic-concepts#model)
- [Origin Model](/as-code/amql/aql-basic-concepts#tables-origin-model)
:::


In AQL, a `Table` is an object that organizes data in the database in rows and columns. An AQL Table is similar to an SQL table, but it has extra properties that allow users to query and transform data flexibly.

### A Table is the result of querying a Model

Suppose that you have defined an `orders` model in the AML layer:

```aml
Model orders {
  dimension id {}
  dimension status {}
  dimension value {}
}
```

When writing AQL code, if you refer to the model `orders`:

```aml
orders
```

This expression will return a **`Table` object** that contains the fields as defined in the model, and all the order data in the database.

When you perform transformations like selection or filtering operations, you will also receive a **`Table` object**:

```aml
orders // <- a table
| select(orders.status, orders.user_id) // <- a table
| filter(orders.status in ['cancelled', 'finished']) // <- table
```

However, after aggregations, you may receive a Table or a Scalar value:

```aml
orders
| group(status)
| select(count: count(orders.id)) // <- a table with the column `count`

orders | count(orders.id) // <- a scalar value
```

<!-- ### Origin model is preserved after transformations -->

<!-- In the example above, when you apply table transformations, the information about the table’s **origin model is preserved as long as the output is still a Table:** -->

<!-- ```aml -->
<!-- orders // <- a table contains all fields inside the orders model -->
<!-- | select(orders.status, orders.user_id) // <- a table contains status and user_id -->
<!-- | filter(orders.status in ['cancelled', 'finished']) // <- same table type -->

<!-- // This still works. Since info about the origin model is -->
<!-- // still retained, you can access orders' fields. -->
<!-- | select(orders.status, orders.user_id) -->
<!-- ``` -->

<!-- However, the origin model of the Table will be lost if you aggregate it to a Scalar value: -->

<!-- ```aml -->
<!-- orders // <- a table contains all fields inside the model of the order -->
<!-- | count(orders.id) -->

<!-- // This will not work. Since the output of Count is a Scalar Value -->
<!-- // which won't have any origin information. -->
<!-- | select(orders.status, orders.user_id) -->
<!-- ``` -->

<!-- Please check out the doc on [Origin Model](/as-code/amql/aql-basic-concepts#tables-origin-model) for more information about this concept. -->
