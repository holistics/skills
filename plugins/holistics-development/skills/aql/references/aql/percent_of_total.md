## Definition

`percent_of_total` calculates the percentage of a metric relative to a specified total type. This function simplifies percentage calculations by automatically handling the division and dimension context in visualizations.

## Syntax

```aml
percent_of_total(metric, total_type)
```

```aml title="Examples"
// Calculate percentage of each row against row total
percent_of_total(orders.total_revenue, 'row_total')

// Calculate percentage of each column against column total
percent_of_total(users.count, 'column_total')

// Calculate percentage against grand total
percent_of_total(products.sales_amount, 'grand_total')

// Using axis aliases for better readability
percent_of_total(orders.count, 'x_axis_total')   // same as 'row_total'
percent_of_total(orders.count, 'legend_total')   // same as 'column_total'
```

## Input

- `metric`: A metric or aggregation expression that you want to calculate the percentage for
- `total_type`: A string specifying which total to use as the denominator:
  - `'row_total'` or `'x_axis_total'`: Percentage of row total (across all columns in that row)
  - `'column_total'` or `'legend_total'`: Percentage of column total (across all rows in that column)
  - `'grand_total'`: Percentage of the overall total

## Output

A percentage value representing the metric's proportion of the specified total. The result is automatically formatted as a percentage (0-100).

## Sample Usages

### Pivot Table with Row and Column Percentages

When working with pivot tables, you can calculate percentages across different dimensions:

```aml
metric users_count = count(ecommerce_users.id);

explore {
  dimensions {
    rows {
      _year: ecommerce_users.created_at | year()
    }
    columns {
      _gender: ecommerce_users.gender
    }
  }

  measures {
    users_count: users_count,
    pct_row: percent_of_total(users_count, 'row_total'),      // % by gender within each year
    pct_col: percent_of_total(users_count, 'column_total'),   // % by year within each gender
    pct_grand: percent_of_total(users_count, 'grand_total'),  // % by both year and gender across all users
  }
}
```

This creates a pivot table showing:
- `pct_row`: What percentage of users in each year belong to each gender
- `pct_col`: What percentage of users of each gender joined in each year
- `pct_grand`: What percentage each cell represents of the total user count

### Using Alias Names

For better readability in visualizations, you can use alias names that correspond to chart axes:

```aml
percent_of_total(users_count, 'x_axis_total')   // same as 'row_total'
percent_of_total(users_count, 'legend_total') // same as 'column_total'
```

### Non-Pivot Tables

When using `percent_of_total` in a regular (non-pivot) table:

```aml
metric users_count = count(ecommerce_users.id);

explore {
  dimensions {
    _year: ecommerce_users.created_at | year(),
    _gender: ecommerce_users.gender
  }

  measures {
    users_count: users_count,
    pct_row: percent_of_total(users_count, 'row_total'),     // 100% (no column grouping)
    pct_col: percent_of_total(users_count, 'column_total'),  // % of grand total
    pct_grand: percent_of_total(users_count, 'grand_total'), // % of grand total
  }
}
```

In non-pivot tables:
- `column_total` and `grand_total` calculate the percentage of the overall total
- `row_total` and `x_axis_total` default to 100% since there is only one column per metric, making the row total equal to the metric value itself


## See Also

- [Level of Detail (LOD) Guide](/as-code/aql/cookbook/level-of-detail)
- [Percent of Total Guide](/as-code/aql/cookbook/aql-percent-of-total)
- [of_all() Function](/reference/aql/of_all)
