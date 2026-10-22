## Measure

Measure syntax defines the measure of a data model. Measure represents an aggregated dimension in a model.

## Parameter

Parameter name      | Description
--------------      | ------------
label               | Specifies how the measure will appear in the Ready-to-explore Dataset
type                | Specifies the data type you want to apply to the measure (currently Holistics only support number/date/datetime)
description         | Add measure description
hidden              | Hides measure from the Exploration interface of Dataset and Report
aggregation_type    | Specify aggregate function of Measure. Currently we only support: **count, count distinct, sum, avg, max, min, median, stdev (sample standard deviation), stdevp (population standard deviation), var (sample variance), varp (population variance), custom (custom sql aggregation)**
definition          | Determines how the measure will be defined or calculated based on SQL queries. Learn more about the definition parameter below. 👇

## SQL Definition of Measure

**Forms:** There are two primary forms that definition for measures can take:

1. **Native Holistics Aggregation Type**: Use aggregation type that Holistics natively supports such as sum, count, count_distinct, avg, etc.. For example:

    ```aml
    measure total_users {
      label: 'Total Users'
      type: 'number'
      // The definition here is the inner expression of the aggregation
      definition: @sql {{ user_id }};;
      aggregation_type: 'count'
    }
    ```

    When used in an explore, this measure will be treated as `COUNT({{ user_id }})`

2. **Custom Aggregation Form** (`aggregation_type: 'custom'` - this is the default when aggregation_type is not specified): The entire definition is used as the aggregation expression. This allows you to use aggregation functions from the source database that are not supported by Holistics (e.g. PERCENTILE_CONT from Redshift).

    ```aml
    measure percentile {
      label: 'percentile'
      type: 'number'
      // must be valid aggregation expression that can be run in
      // aggregation position of a query
      definition: @sql percentile_cont(0.6) within group (order by {{ profit }});;
      aggregation_type: 'custom'
    }
    ```

    ```aml
    SELECT
  col,
  -- ...other group by columns
  COUNT(*) -- The definition of custom aggregation must be an expression
             -- that can be placed here
  FROM orders
  GROUP BY
  1
  -- , ...other group by columns
  ```

  Additionally, you can write a custom measure with calculations between measures:

    ```aml
    measure profit {
      label: 'Profit'
      type: 'number'
      // must be valid aggregation expression that can be run in
      // aggregation position of a query
      definition: @sql {{ measure_revenue }} - {{ measure_cost }} + sum({{ dimension_discount }});;
      aggregation_type: 'custom'
    }
    ```

    However, it's important to note that you **cannot** directly use dimensions without aggregation in a custom measure. For example:

    ```aml
    measure profit {
      label: 'Profit'
      type: 'number'
      // top level must be aggregated
      definition: @sql {{ measure_revenue }} - {{ measure_cost }} + {{ dimension_discount }};;
      aggregation_type: 'custom'
    }
    ```


## Examples
```aml
Model users {
  type: 'table'
  label: "Users"
  description: "This is the AML Users Model"
  table_name: '"ecommerce"."users"'
  data_source_name: 'demodb'

  measure total_users {
    label: 'Total Users'
    type: 'number'
    definition: @sql count({{#SOURCE.id}});;
    aggregation_type: 'custom'
  }
}
```
## FAQs

### How should I define aggregate functions for measures, and what are the important considerations?

- Choose between using `aggregation_type` parameter or using aggregation functions from the database within `definition: @sql ;;` parameter. It’s important to note that you **should not** define an aggregate function in both parameters.
    - If you define an aggregate function using the `aggregation_type`, the `definition: @sql ;;` parameter **must not contain** any aggregate functions.

        ```aml
        //What you should write:
        measure measure_1 {
          ...
          definition: @sql {{ user_id }};;
          aggregation_type: 'count'
        }
        ---------------------------
        //What you should NOT write
        measure measure_1 {
          ...
          definition: @sql count{{ user_id }};;
          aggregation_type: 'count'
        }
        ```

    - If you define the aggregate function within the `definition: @sql ;;` parameter, make sure to set the `aggregation_type` to `custom`.

        ```aml
        //What you should write:
        measure measure_2 {
          ...
          definition: @sql sum({{#SOURCE.id}});;
          aggregation_type: 'custom'
        }
