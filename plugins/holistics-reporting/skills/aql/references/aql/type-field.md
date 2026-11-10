:::tip Knowledge Checkpoint
This documentation assumes you are familiar with the following concepts:
- [Table Type](/reference/aql/type-table)
- [Origin Model](/as-code/amql/aql-concepts-origin)
:::

### Definition

In AQL, a `Field` object is a part of a `Table` object, and it contains additional information that allows AQL to correctly transform your data. For example:

- Field origin: Dimension(orders.status)
- Field’s data type: text, number, truefalse…

In the following section, we will dive deeper into the Field Origin concept.

### Field Origin

Field Origin is an important feature that allows AML to correctly query data and perform aggregations.

The field’s origin consists of three parts:

- **Field class:** Dimension or Measure / Metric
- **The origin model:** the AML model where the field was defined
- **The field’s name** in the AML layer

### Field Origin vs. Table Origin

Unlike Table’s Origin, the Field origin is often not retained after transformation. In other words, most transformation functions when applied on fields will return a **new field without the origin**. 


:::caution
Most transformation functions do not preserve the field’s origin
:::


For example, suppose we have the following `users` model:

```aml
Model users {
  dimension id {}
  dimension first_name {}
  dimension last_name {}
  dimension email {}
  dimension delivered_orders {}
  dimension cancelled_orders {}
}
```

When writing an exploration from the `users` model, we create a new field called `total_orders`:

```aml
users 
| select(
    email,
    delivered_orders,
    cancelled_orders,
    total_orders: users.delivered_orders + users.cancelled_orders
  )
```

Will produce a new Table object with the following fields:

<table>
    <caption>Table (origin: users)</caption>
    <thead>
        <tr>
            <th>Field</th>
            <th>Data Type</th>
            <th>Origin</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>email</td>
            <td>Text</td>
            <td>Dimension(users.email)</td>
        </tr>
        <tr>
            <td>delivered_orders</td>
            <td>Number</td>
            <td>Dimension(users.delivered_orders)</td>
        </tr>
        <tr>
            <td>cancelled_orders</td>
            <td>Number</td>
            <td>Dimension(users.cancelled_orders)</td>
        </tr>
        <tr>
            <td>total_orders</td>
            <td>Number</td>
            <td>None</td>
        </tr>
    </tbody>
</table>


This new `total_orders` field is a new field **without origin**. This field can still be used in later calculations, but it will not be treated as a Dimension or Measure field, and cannot be input of some functions.

:::caution
Fields without origin cannot be used as Dimensions.
:::

In other words, the following expression will be valid:

```aml
users 
| select(
    email,
    delivered_orders,
    cancelled_orders,
    total_orders: users.delivered_orders + users.cancelled_orders
  )
| select(
    email,
    cancellation_rate: cancelled_orders / total_orders
  )
```

And it will produce a new table:

<table>
    <caption>Table (origin: users)</caption>
    <thead>
        <tr>
            <th>Field</th>
            <th>Data Type</th>
            <th>Origin</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>email</td>
            <td>Text</td>
            <td>Dimension(users.email)</td>
        </tr>
        <tr>
            <td>cancellation_rate</td>
            <td>Number</td>
            <td>None</td>
        </tr>
    </tbody>
</table>

However, you cannot use this `total_orders` field as a dimension to group and then aggregate:

```aml
// Count number of users grouped by number of total orders
// However, this is an invalid expression
users 
| select(
    email,
    delivered_orders,
    cancelled_orders,
    total_orders: users.delivered_orders + users.cancelled_orders
)
| group(total_orders) // group() only accept Dimensions
| count(users.email)
```
