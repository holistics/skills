## Introduction

AQL Condition is an expression that lets you apply complex criteria to your [explore](/reference/aql/explore-expression). It follows the structure of the `condition` parameter in the **[where](/reference/aql/where#definition)** function.

Here's an example of an explore with AQL metrics:

```ts
explore {
  dimensions {
      // your_dimensions
  }
  measures {
    orders: total_orders | where(users.gender == 'female' or countries.name == 'Vietnam'),
    revenue: revenue | where(users.gender == 'female' or countries.name == 'Vietnam')  ,
    users: total_users | where(users.gender == 'female' or countries.name == 'Vietnam')
  }
  filters {
    // your_condition
  }
}
```

With AQL Condition, you can streamline the explore like this:

```ts
explore {
  dimensions {
      // your_dimensions
  }
  measures {
    orders: total_orders,
    revenue: revenue,
    users: total_users
  }
  filters {
    //highlight-next-line
    users.gender == 'female' or countries.name == 'Vietnam'
  }
}
```

This approach lets you easily apply advanced filtering to all metrics, helping you get accurate insights from complex data.

For example, you will be able to do:

- Nested Filtering
- Filter multiple fields from different models simultaneously

## How to use

1. Go to the Visualization section.
2. Navigate to the Condition tab.
3. Click on "Add AQL Condition"

![](https://cdn.holistics.io/product/modeling-aql-condition-location-20241211-486.png)


## Sample use cases

### Example 1: Nested Filtering

**Scenario**: You want to find a list of customers who made their first purchase in a specific category (e.g., the gaming category). From this list, you want to understand how many products these customers purchased.

![](https://cdn.holistics.io/product/modeling-nested-filtering-expr-20241211-482.png)

How to Solve This:

1. Obtain a metric that returns the list of customers who made their first purchase in the "Gaming" category.
    
    ```tsx
    // metric name: first_gaming_users
    
    unique(users.name, orders.id, categories.name) 
      | select(
        user_name: users.name,
        order_id: orders.id,
        category_name: categories.name,
        _rank: rank(
          order: min(orders.created_at) | of_all(categories.name),
          partition: users.name
        )
      )
      | filter(_rank == 1, category_name == 'Gaming')
      | select(user_name)
    ```

    ![](https://cdn.holistics.io/product/modeling-first-gaming-users-20241211-487.png)
    
2. Build a visualization showing the total products bought by each user, filtered to the list of users identified in step 1.
  
  ![](https://cdn.holistics.io/product/modeling-aql-condition-demo-20241211-483.png)

### Example 2: Filter multiple fields from different models

**Scenario**: You have a dataset that contains transaction details between buyers and sellers. There is a field called "gender" in both the buyers and sellers models. You want to simultaneously apply the filter to both gender fields to understand the transaction details between male or female buyers and sellers.

![](https://cdn.holistics.io/product/modeling-diagram-filter-multiple-fields-20241211-484.png)

Without filter expression, you would have to apply filter for buyer_gender and seller_gender individually 

![](https://cdn.holistics.io/product/modeling-before-filter-expr-20241211-485.png)

Write an AQL Filter Expression to answer this question:

```tsx
buyers.buyer_gender == 'male'
and 
sellers.seller_gender == 'male'
```

<VideoPlayer src="https://cdn.holistics.io/product/modeling-generic-filter-expr-uc-20241211-480.mp4" />


And if you want your users to apply filter for the Gender of both Buyers and Sellers via Dashboard Filter, you can refer to our [Dynamic Conditions](/docs/modeling/dynamic-conditions) documentation.
