<!-- Deprecated -->

<head>
   <meta name="robots" content="noindex, nofollow"/>
</head>


:::tip Knowledge Checkpoint
A grasp of these concepts will help you understand this documentation better:

- [Cross-Model Reference](/as-code/aql/learn/cross-model)
- [Dimensionalize](/reference/aql/dimensionalize)

:::

## Introduction
**Cohort Analysis** is a methodology that involves studying and analyzing groups of users or customers who share a common characteristic or behavior. 

We will provide a step-by-step walkthrough on how to build a report in Holistics that demonstrates the classic cohort analysis.

<img alt="" title="" src="https://cdn.holistics.io/guides/aql-acquisition-cohort/acquisition-cohort-1.png" width="1019" height="215" />

## Setup
In order to gain insights into the lifetime value of groups of users who were acquired for each particular period of time, our objective is to define and analyze Acquisition Cohorts.

For this tutorial, we will be using an e-commerce dataset that consists of two models: `orders` and `users`. 

Before diving into the implementation, let's take a quick look at our dataset setup. Additionally, the dataset also includes a pre-defined metric called `revenue`, which will be utilized in this tutorial for further analysis.


```aml
// orders.model.aml
Model orders {
  ...
  dimension id {...}
  dimension user_id {}
  dimension created_at {}
}
// users.model.aml
Model users {
  ...
  dimension id {...}
  dimension name {...}
}

// e_commerce.dataset.aml
Dataset e_commerce {
  ...
  models: [orders, users]
  relationships: [
    relationship(orders.user_id > users.id, true)
  ]

  metric revenue {...}
	
  dimension acquisition_year_cohort {
    model: users 
    type: 'date'
    label: 'Acquisition Year Cohort'
    definition: @aql orders
      | min(orders.created_at | year())
      | dimensionalize(users.id) 
    ;;
  }
  
  metric percent_revenue {
    label: 'Percent of Revenue'
    definition: @aql (revenue*1.0) / (revenue | of_all(users.acquisition_year_cohort));;
  }
}
```


_Sample data _
<img alt="" title="" src="https://cdn.holistics.io/guides/aql-acquisition-cohort/context-data-preview.png" width="1069" height="436" />

## High-level flow

1. **Define Acquisition Cohort:** Determine the period and timeframe when each customer was acquired. This period could be daily, monthly, yearly, or any other suitable duration based on your business needs.
2. **Define the metric:** Define the metric you want to observe for each cohort
3. **Bring it together:** Visualize the metrics with each cohort in the pivot table
<img alt="" title="" src="https://cdn.holistics.io/guides/aql-acquisition-cohort/high-level-flow.png" width="1700" height="1306" />

## Implementation

### 1. Define Acquisition Cohort

Let’s define the acquisition cohort as the year that users made their first purchase.

Since  `created_at` in  model `orders` is involved in the expression, `orders` is needed to be placed before [pipe](/reference/aql/operator#pipe) further calculations. This allows `orders` left join `users` based on the relationship we've already defined in the dataset setup. 

[`dimensionalize()`](/reference/aql/dimensionalize) is also applied to group users within the same acquisition period together

```aml
Dataset e_commerce {
  (...)

  dimension acquisition_year_cohort {
    model: users 
    type: 'date'
    label: 'Acquisition Year Cohort'
    definition: @aql orders
      | min(orders.created_at | year())
      | dimensionalize(users.id) 
    ;;
  }

  metric revenue {...}
}
```

<div style={{textAlign: 'center'}}>
  <img src="https://cdn.holistics.io/guides/aql-acquisition-cohort/acquisition-cohort-4.png" width="662" height="188" />
</div>

### 2. Define the Metrics

Create a metric `percent_revenue` which is the [percent of total](/as-code/aql/cookbook/aql-percent-of-total) revenue per each _acquisition cohort_. This metric can also be defined directly on the reporting layer

```aml
Dataset e_commerce {
  ...
  dimension acquisition_year_cohort {...}
  metric revenue {...}

  metric percent_revenue {
    label: 'Percent of Revenue'
    definition: @aql (revenue*1.0) / (revenue | of_all(users.acquisition_year_cohort));;
  }
}
```
<div style={{textAlign: 'center'}}>
  <img src="https://cdn.holistics.io/guides/aql-acquisition-cohort/acquisition-cohort-5.png" width="637" height="233" />
</div>

### 3. Bring it together
We will look at how each `Acquision Cohort` performs over the years. `Revenue` and `Percent of Revenue` metrics will be used to measure their performance

<VideoPlayer src="https://cdn.holistics.io/guides/aql-acquisition-cohort/cohort-analysis-pivot.mov" />

---

We have covered all the foundational concepts required to calculate metrics for the acquisition cohort, and you are now equipped to create even more powerful cohort analysis reports to present to your stakeholders in Holistics.
