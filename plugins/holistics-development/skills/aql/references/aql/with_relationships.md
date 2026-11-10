### Definition
Specifies existing relationships to activate during calculating the measure

This function comes into handy when you have 2 tables that are connected through multiple paths, where only one path can be activated to avoid [ambiguous path](/docs/joins/path-ambiguity).

**Syntax**
```aml
with_relationships(measure, relationship, ...)
```

```aml title="Examples"
// Activate the relationship between order_items and products
sum(order_items.revenue) | with_relationships(order_items.product_id > products.id)
```

**Input**
- `measure`: A measure that you want to override the relationships
- `relationship` (**repeatable**): A relationship that you want to activate. It comes in 2 forms:
  - `model1.column1 > model2.column2` (many-to-one). E.g. `order_items.product_id > products.id`
  - `model1.column1 - model2.column2` (one-to-one). E.g. `merchants.admin_id - users.id`

  <div style={{padding: 5}}></div>

  :::caution
  Only relationships that are already defined in the dataset can be used in `with_relationships`
  :::

**Output**

Measure with specified relationships.
:::caution
Relationships activated by `with_relationships` will have priority over normal relationships, **but the relationship path in the highest tier will still always be used**. See path [prioritization algorithm](#prioritization-algorithm).
:::

---

### Path Prioritization Algorithm {#prioritization-algorithm}
When multiple paths exist from the **filter/dimension model** to the **target metric model**, AQL choose the most optimal path using this algorithm.

#### Rank the path using the following criteria:

a. **Tier Precedence** *(Lower tier is better)*

- **Tier 1** paths always rank higher than **Tier 2+** paths.
- If multiple paths are in the same tier, proceed to **Weight Comparison**.

b. **Weight Comparison** *(Higher weight is better)*

- Compare the weights of the paths.
- If one path has a relationship with a **higher weight**, it ranks higher.
- If weights are **equal**, proceed to **Path Length**.

c. **Path Length** *(Shorter is better)*

- Among paths with equal tier and weight, choose the one with the **shortest length**.
- If lengths are **equal**, paths are considered **equivalent**.

#### Final Decision

- If there is **one clear winner**, **use it**.
- If paths are **equivalent** with no clear winner:
  - **Throw an error**
  - Ask users to **add `with_relationships()`** to clarify intent

#### Tier Explanation

| **Tier** | **Description**                                                                                                           |
|----------|---------------------------------------------------------------------------------------------------------------------------|
| Tier 1   | Path contains **only one-to-many** relationships (filters flow from dim to fact model)                                    |
| Tier 2   | Path contains **only many-to-one** relationships (filters flow from fact to dim model)                                    |
| Tier 3   | Path follows the [many-to-many](/docs/relationships#handling-many-to-many-n-n-relationship) with a junction table pattern |
| Tier 4   | Path contains a **mixed pattern** not conforming to the above                                                             |

## Relationship Weight

- Each relationship in a path has a **default weight of 0**.
- `with_relationships()` given weight to relationships, nested one will be given more weight.
```aml
with_relationships(
  metric_1,
  with_relationships(
    metric_2,
    order_items.product_id > products.id // this will have higher weight than the one below
  )
  merchants.admin_id > users.id
)
```

### Sample Usages
Consider the scenario where we have two facts models `order_items` and `shippings`, both connected to the dimension models `products`, `orders`, and `countries`. 

<div style={{textAlign: 'center'}}>
  <img src="https://cdn.holistics.io/docs/as-code/relationship/with_relationships_example.png" width="700" height="560"></img>
</div>


In order to avoid ambiguous paths, for `order_items` relationships, we can only activate one link between `order_items` and `products`, and deactivate the other links.  While deactivating these relationships, we still need to keep those definitions in order to reuse it in `with_relationships`. 

```aml
Dataset e_commerce {
  (...)
  
  relationships: [
    // shippings relationships
    relationship(shippings.product_id > products.id, true),
    relationship(shippings.order_id > orders.id, true),
    relationship(shippings.country_id > countries.id, true),
    
    // order_items relationships
    relationship(order_items.product_id > products.id, true),
    relationship(order_items.order_id > orders.id, false), // deactivated
    relationship(order_items.country_id > countries.id, false) // deactivated
  ]
}
```

Then override the deactivated relationships in the measure/metric definition using `with_relationships`. We can also omit the link from `order-items`-`products` since we already activate it in the dataset. 

  ```aml
  Model order_items {
    (...)
    
    measure total_sales {
      label: 'Total Sales'
      type: 'number'
      definition: @aql 
        sum(order_items.revenue) | 
        with_relationships(
          // You can omit the first relationship as it is already activated in the dataset
          // order_items.product_id > products.id,
          order_items.order_id > orders.id,
          order_items.country_id > countries.id,
        )
      ;;
    }
  }
  ```

## See also

- [Relationships](/reference/aml/relationship): concept
- [Common Relationship Problems](/as-code/reference/common-relationships-problems)
- [Metric Context](/as-code/aql/learn/metric-context)
