<!-- Moved to /docs/dsets/dataset-path-ambiguity -->

:::tip Knowledge Checkpoint
A grasp of these concepts will help you understand this documentation better:

- [with_relationships](/reference/aql/with_relationships)

:::

## Introduction

There may be instances when you need to disable certain relationships within your Dataset to avoid [ambiguities in the join path](/docs/joins/path-ambiguity). Yet, there are a lot of cases where the disabled relationships are required to compute a metric.

:::tip Measures and Metrics

You may see the use of `measure` in code snippets throughout this article. In Holistics, metrics defined inside data models are syntactically referred to as `measure`. We will use the word "metric" outside of code snippets to avoid confusions. [Read more about Metrics here](/as-code/aql/learn/what-aql-is-for)

:::

For clarity on these scenarios, please refer to the two examples provided below.

## Example 1: Role-playing Dimension

### What is Role-playing Dimension

In Star Schema design, a **role-playing dimensions** are dimensions that are used more than once in a fact table, each time with a different meaning or role.

In Holistics, this design can be imitated by creating multiple relationships between two tables. for example, in an Ecommerce company, the date dimension model has three relationships to the `Orders` facts. The same dimension table can be used to filter the facts by order date, delivery date, or cancelled date.

<img alt="Role Playing Dim Date Orders" title="" src="https://cdn.holistics.io/docs/v4/amql/muilti-relationships/role-playing-dim-date-orders.png" width="811" height="447" />

While this design is possible, it's important to understand that there can only be one active relationship between two Holistics models. All remaining relationships must be disabled to make this Dataset not being ambiguous. 

Having a single active relationship means there is a default filter propagation from `date` dim model to `orders` fact model. In this instance, the active relationship is set to the most common filter that is used by reports, which is the `Date → Orders Created Date` and what you can only answer is how many orders has been created (instead of how many orders that has been `delivered` or `cancelled`)

### How to overcome this problem

The method is to handle inactive relationship is to use a function in AQL called `with_relationship()` ([Learn more here](/reference/aql/with_relationships)). The function literally telling Holistics that for this expression, use this relationship, even if it is inactive.

Let’s say that we want to understand how many Orders have been delivered, cancelled, refunded, you can create the metrics as below

```tsx
Dataset role_playing_dim {
  models: [
    fct_orders,
    dim_dates
  ]
  relationships: [
    relationship(fct_orders.created_at > dim_dates.date, true),
    relationship(fct_orders.cancelled_at > dim_dates.date, false),
    relationship(fct_orders.delivered_at > dim_dates.date, false),
    relationship(fct_orders.refunded_at > dim_dates.date, false)
  ]

	// AQL Metrics
	metric total_created_orders { 
		label: 'Total Created Orders'
		type: 'number'
		definition: @aql fct_orders | count(fct_orders.id);;
	}
	
	metric total_delivered_orders {
		label: 'Total Delivered Orders'
		type: 'number'
		definition: @aql 
			fct_orders 
			  | count(fct_orders.id)
			  | with_relationships(fct_orders.delivered_at > dim_dates.date)
		;;
	}

	metric total_cancelled_orders {
		label: 'Total Cancelled Orders'
		type: 'number'
		definition: @aql 
			fct_orders 
			  | count(fct_orders.id)
			  | with_relationships(fct_orders.cancelled_at > dim_dates.date)
		;;
	}
	
	metric total_refunded_orders {
		label: 'Total Refunded Orders'
		type: 'number'
		definition: @aql 
			fct_orders 
			  | count(fct_orders.id)
			  | with_relationships(fct_orders.refunded_at > dim_dates.date)
		;;
	}
}
```

And then when you use these metrics altogether, you will get the Result like below

```tsx
explore {
	dimensions {
		dim_dates.date
	}
	// Note that metrics defined in models are called measures
	measures {
		total_created_orders,
		total_delivered_orders,
		total_cancelled_orders,
		total_refunded_orders
	}
}
```

<img alt="Chart Role Playing Dim" title="" src="https://holistics-cdn.s3.ap-southeast-1.amazonaws.com/docs/v4/amql/muilti-relationships/chart-role-playing.png" width="1563" height="847" />

## Example 2: Fact Constellation Schema Design

### What is Fact Constellation Schema?

Fact Constellation Schema is also known as Galaxy Schema that further divides Star Schema in small Star Schema(s) where there are more than one Fact Tables and Reusable dimension to connect multiple Fact Tables.

For example, you could have a fact table for `orders` and another fact table for `inventory`, both linked to the same dimension tables for `products`, `dates`. 

In Holistics, in order for this Dataset to be functional without facing the ambiguous error, you would have to disable 1 relationship from dim to fact. For example, in this case, I will disable the relationship from Products to Inventory

<img alt="Fact Constellation Schema" title="" src="https://holistics-cdn.s3.ap-southeast-1.amazonaws.com/docs/v4/amql/muilti-relationships/fact_constellation_schema.png" width="1164" height="723" />

With this relationship setup, you’re unable to find out what are the Total Quantity Available for a specific product just by using the Drag and Drop in the Dataset Explore because the direct relationship between Products and Inventory is inactive. 

This implies that, in the Dataset Explore, when you use the combination of Product Name and Sum of Quantity Available, instead of the filtering direction goes from `Products → Inventory`, it will go from `Products → Orders → Dates → Inventory` which is analytically incorrect.

### What is the solution?

What is you want to build a Report that tells

- Total Quantity Available by Product
- Total GMV by Product
- Filtered by Month

One of the solution can be done here is to use `with_relationship()` in the context of the metric Total Quantity Available by Product

```tsx
Dataset galaxy_schema {
  models: [
    fct_inventory,
    dim_products,
    fct_orders,
    dim_dates
  ]
  relationships: [
    relationship(fct_orders.product_id > dim_products.id, true),
    relationship(fct_inventory.product_id > dim_products.id, false),
    relationship(fct_orders.created_at > dim_dates.date, true),
    relationship(fct_inventory.created_at > dim_dates.date, true)
  ]

  // AQL Metrics here
  metric total_available_products {
    label: 'Total Available Quantity Product'
    type: 'number'
    definition: @aql 
      fct_inventory 
        | sum(fct_inventory.quantity_available) 
        | with_relationships(fct_inventory.product_id > dim_products.id) 
      ;;
  }
}
```

And then when using it in the Dataset Explore to build the report, you will get the Result like below

```tsx
explore {
	dimensions {
		dim_products.name
	}
	// Note that metrics defined in models are called measures
	measures {
		total_available_products,
		total_gmv_by_products: sum(fct_orders.item_values)
	}
	filters {
		dim_dates.date matches @(last 6 months)
	}
}
```

<img alt="Result Fact Constellation Schema" title="" src="https://cdn.holistics.io/docs/v4/amql/muilti-relationships/result_fact_constellation_schema.png" width="1100" height="728" />
