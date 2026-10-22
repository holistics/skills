import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';
import SampleCode from '@site/src/components/SampleCode';

:::tip Knowledge Checkpoint
A grasp of these concepts will help you understand this documentation better:

- [Cross-Model Reference](/as-code/aql/learn/cross-model)

:::

## Overview
In most analytic setups, data are organized across multiple [models](/reference/aml/model). Thus, it is often necessary to perform calculations that involve data from multiple models. For example, in an e-commerce dataset, you may want to make calculations that involves data from orders, users, and products models. In AQL, this is called **cross-model calculation**.

In this guide, you will learn how to perform cross-model calculation in AQL. If you want to learn more about the concepts behind cross-model calculation, please refer to its [reference](/as-code/aql/learn/cross-model) page.

## Prerequisites
This guide assumes that you have a basic understanding of the following concepts:
- How to [define data models](/reference/aml/model)
- How to [define data sets](/reference/aml/dataset)
- How to [define relationships](/reference/aml/relationship)

## Setup
To start, visit the following AQL playground ([link](https://go.holistics.io/U6L8M)) and examine the `ecommerce` dataset. This dataset contains 4 models: `users`, `products`, `orders`, and `order_items`. The relationships between these models are defined as follows:

<iframe className='aspect-ratio-16/9' src='https://dbdiagram.io/e/65a4be9cac844320aee87eb0/65a4c217ac844320aee8a95f' />

You are free to modify the dataset and the models as you see fit, or using different models and relationships in your own project. But for the purpose of this guide, we will use the `ecommerce` dataset as an example.

## Implementation

### Defining your first cross-model dimension
Let's say you want to create a dimension that contains the actual value of each order item in the `order_items` model with the following definition:

$$
\text{item value} = \text{item quantity} \times \text{product price}
$$

Examining the `order_items` model, you will see that it only has a `quantity` column and a `product_id` column, and does not contain the price of the product. Thus, you need to somehow access the price of the corresponding product in the `products` model.

<img alt="users model and order items model with price and quantity highlighted" title="" src="https://cdn.holistics.io/docs/as-code/guides/cross-model/quantity_times_price.png" width="497" height="230" />

In AQL, this is a simple matter of:

1. Define a relationship between the `order_items` model and the `products` model.

  ```aml
  Dataset ecommerce {
    /* ... */

    relationships: [
      relationship(order_items.order_id > orders.id, true),
      // highlight-next-line
      relationship(order_items.product_id > products.id, true),
      /* ... */
    ]
  }
  ```

2. Define the `value` dimension directly referencing `products.price` in the `order_items` model. (You can also define it at the [dataset level](/as-code/aql/where-to-define-aql#aql-dimensions))

  ```aml
  Model order_items {
    /* ... */

      dimension value {
        label: 'value'
        type: 'number'
        // highlight-next-line
        definition: @aql order_items.quantity * products.price ;;
      }
    }
    ```

import { example1 } from './aql_cross_model_calculation.js';

3. Test the new dimension.

    <SampleCode rawResult={example1} />

### Defining your first cross-model metric

Similar to the previous example, let's say you want to create a metric to calculate the total value of all order items in the `order_items` model with the following definition:

$$
\text{total value} = \sum_{\text{item} \in \text{order items}} \text{item value}
$$

This time, since you already defined the relationship between the `order_items` model and the `products` model, you can simply use the [sum](/reference/aql/aggregator-functions#sum) function to aggregate the `value` dimension you defined in the previous example.

```aml
Model order_items {
  /* ... */

  // note that metrics defined in model are called measures
  measure total_value {
    label: 'Total Value'
    type: 'number'
    // highlight-next-line
    definition: @aql sum(order_items.value) ;;
  }
}
```

import { example2 } from './aql_cross_model_calculation.js';

<SampleCode rawResult={example2} />

If you want, you can skip the `value` dimension and define the `total_value` metric directly.

```aml
Model order_items {
  /* ... */

  // note that metrics defined in model are called measures
  measure total_value {
    label: 'Total Value'
    type: 'number'
    // highlight-next-line
    definition: @aql sum(order_items, order_items.quantity * products.price) ;;
  }
}
```


## Conclusion
In this guide, you have learned how to make cross-model calculation in AQL. If you want to learn more about the concepts behind cross-model calculation, please refer to its [reference](/as-code/aql/learn/cross-model) page.
