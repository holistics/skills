# Viz examples

Each example pairs a request (often with its AQL explore and dataset fields) with the resulting title and Viz AML. BAD examples show common mistakes and why they're wrong.

## Example 1
### User request
This is my current AQL:
```aql
metric revenue = order_items | sum(order_items.quantity * products.price);
explore {
  dimensions {
    country: country.name,
  }
  measures {
    revenue: revenue,
  }
  filters {
    country.continent == 'Asia',
  }
}
```

Create a pie chart of revenue by country in Asia.
### Viz
title: Revenue by country in Asia
viz: |-
  PieChart {
    dataset: ecommerce
    calculation revenue { // adhoc metric declared in AQL
      label: 'Revenue'
      formula: @aql order_items | sum(order_items.quantity * products.price);;
      calc_type: 'measure'
      data_type: 'number'
      model: '' // Measure calculation => Do **NOT** specify model
    }
    legend: r(country.name)
    series {
      field: 'revenue'
    }
    conditions: [
      "country.continent == 'Asia'",
    ]
    settings {
      group_values_into: 10
    }
  }

## Example 2
### User request
This is my current AQL:
```aql
dimension country.upper_name = upper(country.name);
metric revenue = order_items | sum(order_items.quantity * products.price);
explore {
  dimensions {
    time: orders.created_at | month(),
    country: country.upper_name,
  }
  measures {
    total_revenue: revenue,
    user_count: count(users.id),
  }
  filters {
    country.continent == 'Asia',
  }
}
```

Show revenue and user count by year of countries in Asia.
### Viz
title: Revenue by country in Asia
viz: |-
  CombinationChart {
    dataset: ecommerce
    calculation country_upper_name { // adhoc dimension declared in AQL
      label: 'Country Name (Uppercase)'
      formula: @aql upper(country.name);;
      calc_type: 'dimension'
      data_type: 'text'
      model: country // Dimension calculation -> MUST specify model
    }
    // NOTE: inline AQL expressions must be converted to Viz calculation
    calculation revenue { // adhoc metric declared in AQL
      label: 'Total Revenue'
      formula: @aql order_items | sum(order_items.quantity * products.price);;
      calc_type: 'measure'
      data_type: 'number'
      model: '' // Measure calculation => Do **NOT** specify model
    }
    calculation user_count { // adhoc metric declared in AQL
      label: 'User Count'
      formula: @aql count(users.id);;
      calc_type: 'measure'
      data_type: 'number'
      model: '' // Measure calculation => Do **NOT** specify model
    }
    x_axis: VizFieldFull {
      ref: r(orders.created_at)
      transformation: 'datetrunc month'
      format {
        type: 'date'
      }
    }
    legend: VizFieldFull {
      label: 'Country Name'
      ref: ref('country', 'country_upper_name')
    }
    y_axis {
      series {
        mark_type: 'line'
        field: VizFieldFull {
          label: 'Total Revenue'
          ref: 'revenue'
          format {
            type: 'number'
            pattern: '#,###,"K"'
          }
        }
      }
      settings {
        group_values_into: 10
      }
    }
    y_axis {
      series {
        mark_type: 'column'
        field: 'user_count'
      }
      settings {
        alignment: 'right'
        group_values_into: 10
      }
    }
    conditions: [
      "country.continent == 'Asia'",
    ]
  }

## Example 3
### User request
This is my current AQL:
```aql
metric revenue = order_items | sum(order_items.quantity * products.price);
explore {
  dimensions {
    country: country.name,
  }
  measures {
    revenue: revenue,
  }
  filters {
    country.continent == 'Asia',
  }
}
```

Show revenue by country in Asia, highlighting those whose revenue > 100.
### Viz
title: Revenue by country in Asia, highlighting those whose revenue > 100
viz: |-
  DataTable {
    dataset: ecommerce
    calculation revenue {
      label: 'Revenue'
      formula: @aql order_items | sum(order_items.quantity * products.price);;
      calc_type: 'measure'
      data_type: 'number'
      model: '' // Measure calculation => Do **NOT** specify model
    }
    fields: [
      r(country.name),
      'revenue',
    ]
    conditions: [
      "country.continent == 'Asia'",
    ]
    settings {
      conditional_formats: [
        ConditionalFormat {
          ref: 'revenue'
          format: SingleFormat {
            condition {
              operator: 'greater_than'
              value: 100
            }
            text_color: '#328159'
            background_color: '#B5E3CD'
            apply_to_row: true
          }
        }
      ]
    }
  }

## Example 4
### User request
dataset_fields:
  dimensions:
    - name: name
      type: text
      model: country
    - name: continent
      type: text
      model: country
  measures:
    - name: revenue
      type: number
      aql: order_items | sum(order_items.quantity * products.price)
      model: ''
  datasets:
    ecommerce: {}

This is my current AQL:
```aql
explore {
  dimensions {
    country: country.name,
  }
  measures {
    revenue: revenue,
  }
  filters {
    country.continent == 'Asia',
  }
}
```

Create a pie chart of revenue by country in Asia.
### Viz
title: Revenue by country in Asia
viz: |-
  PieChart {
    dataset: ecommerce
    legend: r(country.name)
    series {
      field: r(ecommerce.revenue)
    }
    conditions: [
      "country.continent == 'Asia'",
    ]
    settings {
      group_values_into: 10
    }
  }

## Example 5
### User request
dataset_fields:
  dimensions:
    - name: name
      type: text
      model: country
    - name: continent
      type: text
      model: country
  measures:
    - name: revenue
      type: number
      aql: order_items | sum(order_items.quantity * products.price)
      model: ''
  datasets:
    ecommerce: {}

This is my current AQL:
```aql
explore {
  dimensions {
    country: country.name,
  }
  measures {
    revenue: revenue,
  }
  filters {
    country.continent == 'Asia',
  }
}
```

Create a markdown of revenue by country in Asia.
### Viz
title: Revenue by country in Asia
viz: |-
  MarkdownViz {
    dataset: ecommerce
    rows: [
      VizFieldFull {
        ref: r(country.name)
        label: 'Country Name'
      }
    ]
    values: [
      VizFieldFull {
        ref: r(ecommerce.revenue),
        label: 'Revenue'
      }
    ]
    conditions: [
      "country.continent == 'Asia'",
    ]
    content: @md
      <style>
      .tiles {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
        gap: 1.5rem;
        padding: 1.5rem 0;
      }
      .tile {
        border: 1px solid #E5E7EB;
        border-radius: 10px;
        background: #FAFAFA;
        padding: 1.25rem 1.5rem;
        box-shadow: 0 1px 4px rgba(0,0,0,0.03);
        display: flex;
        flex-direction: column;
        min-height: 180px;
      }
      .title {
        font-size: 1.1rem;
        font-weight: 600;
        color: #1E293B;
        margin-bottom: 0.5rem;
      }
      .meta {
        font-size: 0.93rem;
        color: #475569;
        margin-bottom: 0.25rem;
      }
      .label {
        font-weight: 500;
        color: #64748B;
        margin-right: 0.3rem;
      }
      </style>

      <div class="tiles">
      {% map(rows) %}
        <div class="tile">
          <div class="title">{{ `Country Name` }}</div>
          <div class="meta"><span class="label">Revenue:</span>{{ `Revenue` }}</div>
        </div>
      {% end %}
      </div>
    ;;
  }

## Example 6
### User request
dataset_fields:
  dimensions:
    - name: name
      type: text
      model: country
    - name: continent
      type: text
      model: country
  measures:
    - name: revenue
      type: number
      aql: order_items | sum(order_items.quantity * products.price)
      model: ''
  datasets:
    ecommerce: {}

This is my current AQL:
```aql
explore {
  dimensions {
    country: country.name,
  }
  measures {
    revenue: revenue,
  }
  filters {
    country.continent == 'Asia',
  }
}
```

Create a red bar chart of revenue by country in Asia, sorted in descending revenue.
### Viz
title: Revenue by country in Asia
viz: |-
  BarChart {
    dataset: ecommerce
    x_axis: VizFieldFull {
      ref: r(country.name)
    }
    y_axis {
      series {
        field: VizFieldFull {
          ref: r(ecommerce.revenue)
        }
        settings {
          color: '#F1434B'
        }
      }
    }
    conditions: [
      "country.continent == 'Asia'",
    ]
    settings {
      sort: LineFamilySort {
        type: 'yaxis'
        field_index: 0 // first y axis
        direction: 'desc'
      }
    }
  }

## Example 7
### User request
dataset_fields:
  dimensions:
    - name: name
      type: text
      model: country
    - name: continent
      type: text
      model: country
    - name: name
      type: text
      model: city
  measures:
    - name: revenue
      type: number
      aql: order_items | sum(order_items.quantity * products.price)
      model: ''
  datasets:
    ecommerce: {}

This is my current AQL:
```aql
explore {
  dimensions {
    city: city.name,
  }
  measures {
    revenue: revenue,
  }
  filters {
    country.continent == 'Asia',
  }
}
```

Create a red bar chart of revenue by country in Asia, broken down by city, sorted by country name alphabetically.
### Viz
title: Revenue by country in Asia
viz: |-
  BarChart {
    dataset: ecommerce
    x_axis: VizFieldFull {
      ref: r(country.name)
    }
    legend: r(city.name)
    y_axis {
      series {
        field: VizFieldFull {
          ref: r(ecommerce.revenue)
        }
        settings {
          color: '#F1434B'
        }
      }
    }
    conditions: [
      "country.continent == 'Asia'",
    ]
    settings {
      sort: LineFamilySort {
        type: 'xaxis'
        direction: 'asc'
      }
    }
  }

## Example 8
### User request
dataset_fields:
  dimensions:
    - name: name
      type: text
      model: country
    - name: continent
      type: text
      model: country
    - name: name
      type: text
      model: city
  measures:
    - name: revenue
      type: number
      aql: order_items | sum(order_items.quantity * products.price)
      model: ''
  datasets:
    ecommerce: {}

This is my current AQL:
```aql
explore {
  dimensions {
    country: country.name,
  }
  measures {
    c_1a_2d: count(city.name),
  }
  filters {
    country.continent == 'Asia',
  }
}
```

This is my current Viz AML:
```aml
PivotTable {
  dataset: ecommerce
  rows: [
    VizFieldFull {
      ref: r(country.name)
    }
  ]
  values: [
    VizFieldFull {
      ref: r(city.name)
      aggregation: 'count'
    }
  ]
  conditions: [
    "country.continent == 'Asia'",
  ]
}


```

Create a bar chart of city count by country in Asia.
### Viz
title: Revenue by country in Asia
viz: |-
  BarChart {
    dataset: ecommerce
    x_axis: VizFieldFull {
      ref: r(country.name)
    }
    y_axis {
      series {
        field: VizFieldFull {
          ref: r(city.name)
          aggregation: 'count'
        }
      }
    }
    conditions: [
      "country.continent == 'Asia'",
    ]
    settings {
      sort: LineFamilySort {
        type: 'xaxis'
        direction: 'asc'
      }
    }
  }

## Example 9
### User request
dataset_fields:
  dimensions:
    - name: name
      type: text
      model: country
    - name: continent
      type: text
      model: country
    - name: name
      type: text
      model: city
    - name: time
      type: date
      model: orders
  measures:
    - name: revenue
      type: number
      aql: order_items | sum(order_items.quantity * products.price)
      model: ''
  datasets:
    ecommerce: {}

This is my current AQL:
```aql
explore {
  dimensions {
    time: orders.time | month(),
  }
  measures {
    revenue: revenue,
  }
}
```

Create a column chart of revenue by month.
### Viz
title: Revenue by country in Asia
viz: |-
  ColumnChart {
    dataset: ecommerce
    x_axis: VizFieldFull {
      ref: r(orders.time)
      transformation: 'datetrunc month'
      // IMPORTANT: always format date fields
      format {
        type: 'date'
      }
    }
    y_axis {
      series {
        field: VizFieldFull {
          ref: r(ecommerce.revenue)
        }
      }
    }
    settings {
      sort: LineFamilySort {
        type: 'xaxis'
        direction: 'asc'
      }
    }
  }

## Example 10
### User request
dataset_fields:
  datasets:
    demo_ecommerce: {}

This is my current AQL:
```aql
dimension users.acquisition_cohort_month = min(orders.created_at | month()) | dimensionalize(users.id);
dimension orders.cohort_month_number = date_diff('month', users.acquisition_cohort_month, (orders.created_at | month()));
metric total_users = users | count(users.id);

explore {
  dimensions {
    acquisition_month: users.acquisition_cohort_month,
    cohort_month_number: orders.cohort_month_number,
  }
  measures {
    user_count: total_users,
    retention: (total_users * 1.0) / (total_users | of_all(orders.cohort_month_number, keep_filters: true)),
  }
  sorts {
    acquisition_month ASC,
    cohort_month_number ASC,
  }
}
```

Create a pivot table to show the cohort retenttion.

### Viz
title: Cohort Retention by Month
viz: |-
  PivotTable {
    dataset: demo_ecommerce
    calculation acquisition_cohort_month {
      label: 'Acquisition Month'
      formula: @aql min(orders.created_at | month()) | dimensionalize(users.id);;
      calc_type: 'dimension'
      data_type: 'datetime'
      model: users
    }
    calculation cohort_month_number {
      label: 'Month number'
      formula: @aql date_diff('month', users.acquisition_cohort_month, (orders.created_at | month()));;
      calc_type: 'dimension'
      data_type: 'number'
      model: orders
    }
    calculation total_users {
      label: 'Total Users'
      formula: @aql users | count(users.id);;
      calc_type: 'measure'
      data_type: 'number'
    }
    calculation retention_rate {
      label: 'Retention Rate'
      formula: @aql (total_users * 1.0) / (total_users | of_all(orders.cohort_month_number, keep_filters: true));;
      calc_type: 'measure'
      data_type: 'number'
    }
    rows: [
      VizFieldFull {
        ref: ref('users', 'acquisition_cohort_month')
        label: 'Cohort Month'
        format {
          type: 'date'
          pattern: 'LLL yyyy'
        }
      }
    ]
    columns: [
      VizFieldFull {
        ref: ref('orders', 'cohort_month_number')
        label: 'Nth Month'
        format {
          type: 'number'
          pattern: 'inherited'
        }
      }
    ]
    values: [
      VizFieldFull {
        ref: 'total_users'
        label: 'User Count'
        format {
          type: 'number'
          pattern: '#,###0'
        }
      }
      VizFieldFull {
        ref: 'retention_rate'
        label: 'Retention Rate'
        format {
          type: 'number'
          pattern: '#,###0.0%'
        }
      }
    ]
    settings {
      show_row_total: false
      show_column_total: false
      show_sub_total: false
      conditional_formats: [
        ConditionalFormat {
          ref: 'retention_rate'
          format: ScaleFormat {
            min {
              value: 0
              color: '#FEE2E2'
            }
            mid {
              value: 0.2
              color: '#FDE68A'
            }
            max {
              value: 1
              color: '#BBF7D0'
            }
          }
        }
      ]
      sorts: [
        KeyBasedSortSetting {
          key: 'users.acquisition_cohort_month'
          direction: 'asc'
        },
        KeyBasedSortSetting {
          key: 'orders.cohort_month_number'
          direction: 'asc'
        }
      ]
      pagination_size: 100
      show_row_with_no_data: false
      wrap_header_text: true
      wrap_cell_text: true
    }
  }

## Example 11
### User request
dataset_fields:
  dimensions:
    - name: created_at
      type: datetime
      model: orders
    - name: category
      type: text
      model: products
  measures:
    - name: revenue
      type: number
      aql: order_items | sum(order_items.quantity * products.price)
      model: ''
  params:
    - name: category_param
      type: text
      model: products
    - name: date_param
      type: datetime
      model: orders
  datasets:
    ecommerce: {}

This is my current AQL:
```aql
explore {
  dimensions {
    month: orders.created_at | month(),
  }
  measures {
    revenue: revenue,
  }
  params {
    products.category_param in ['Books', 'Toys'],
    orders.date_param matches @(last 6 months),
  }
  sorts {
    month ASC,
  }
}
```

Show it as a column chart.
### Viz
title: Monthly revenue of Books and Toys
viz: |-
  ColumnChart {
    dataset: ecommerce
    x_axis: VizFieldFull {
      ref: r(orders.created_at)
      transformation: 'datetrunc month'
      format {
        type: 'date'
        pattern: 'LLL yyyy'
      }
    }
    y_axis {
      series {
        field: VizFieldFull {
          ref: r(ecommerce.revenue)
          format {
            type: 'number'
            pattern: 'inherited'
          }
        }
      }
    }
    filter { // param assignment, NOT a condition
      field: r(products.category_param)
      operator: 'is' // `in` becomes `is` with a list value
      value: ['Books', 'Toys']
    }
    filter {
      field: r(orders.date_param)
      operator: 'matches'
      value: 'last 6 months' // the text inside @()
    }
  }

## Example 12
### User request
This is my current AQL:
```aql
explore {
  dimensions {
    product_sku: products.sku,
    product_name: products.name,
  }
  measures {
    quantity: order_items | sum(order_items.quantity),
  }
}
```

Plot a bar chart using product name as the category and quantity as the value.
### Viz
title: Quantity by product
notes: Product SKU doesn't fit a bar chart with product name as the category, so it's shown as a list in the tooltip.
viz: |-
  BarChart {
    dataset: ecommerce
    calculation quantity {
      label: 'Quantity'
      formula: @aql order_items | sum(order_items.quantity);;
      calc_type: 'measure'
      data_type: 'number'
      model: ''
    }
    calculation product_skus { // folds the product_sku dimension
      label: 'Product SKUs'
      formula: @aql string_agg(products.sku, sep: ', ');;
      calc_type: 'measure'
      data_type: 'text'
      model: ''
    }
    x_axis: r(products.name)
    y_axis {
      series {
        field: 'quantity'
      }
    }
    tooltips: [
      VizTooltip {
        field: 'product_skus' // NEVER put a raw dimension such as r(products.sku) here
      }
    ]
  }

## Example 13
### User request
This is my current AQL:
```aql
metric revenue = order_items | sum(order_items.quantity * products.price);
explore {
  dimensions {
    category: products.category,
    month: orders.created_at | month(),
  }
  measures {
    revenue: revenue,
  }
}
```

Show revenue by category as a pie chart.
### Viz
title: Revenue by category
notes: A pie chart can't fit the order month, and listing every month in the tooltip would be unreadable, so it's dropped. Each slice shows revenue across all months.
viz: |-
  PieChart {
    dataset: ecommerce
    calculation revenue {
      label: 'Revenue'
      formula: @aql order_items | sum(order_items.quantity * products.price);;
      calc_type: 'measure'
      data_type: 'number'
      model: ''
    }
    legend: r(products.category)
    series {
      field: 'revenue'
    }
  }

## BAD Example 1
### User request
This is my current AQL:
```aql
metric revenue = order_items | sum(order_items.quantity * products.price);
explore {
  dimensions {
    country: country.name,
  }
  measures {
    revenue: revenue,
  }
  filters {
    country.continent == 'Asia',
  }
}
```

Create a pie chart of revenue by country in Asia.
### Viz
title: Revenue by country in Asia
viz: |-
  PieChart {
    dataset: ecommerce
    legend: r(country.name)
    series {
      field: 'revenue'
    }
    conditions: [
      "country.continent == 'Asia'",
    ]
    settings {
      group_values_into: 10
    }
  }

### BAD reason
Missing Viz calculation definition for `revenue`.

## BAD Example 2
### User request
This is my current AQL:
```aql
dimension country.upper_name = upper(country.name);
metric revenue = order_items | sum(order_items.quantity * products.price);
explore {
  dimensions {
    time: orders.created_at | month(),
    country: country.upper_name,
  }
  measures {
    total_revenue: revenue,
    user_count: count(users.id),
  }
  filters {
    country.continent == 'Asia',
  }
}
```

Show revenue and user count by year of countries in Asia.
### Viz
title: Revenue by country in Asia
viz: |-
  CombinationChart {
    dataset: ecommerce
    x_axis: VizFieldFull {
      ref: r(orders.created_at)
      transformation: 'datetrunc month'
      format {
        type: 'date'
      }
    }
    legend: VizFieldFull {
      label: 'Country Name'
      ref: ref('country', 'country_upper_name')
    }
    y_axis {
      series {
        mark_type: 'line'
        field: VizFieldFull {
          label: 'Total Revenue'
          ref: 'revenue'
          format {
            type: 'number'
            pattern: '#,###,"K"'
          }
        }
      }
      series {
        mark_type: 'column'
        field: 'user_count'
      }
      settings {
        group_values_into: 10
      }
    }
    conditions: [
      "country.continent == 'Asia'",
    ]
  }

### BAD reason
* Missing Viz calculation definition for `revenue`.
* Missing Viz calculation definition for `country.upper_name`.
* Missing Viz calculation definition for `user_count`.
* `Total Revenue` and `User Count` share one `y_axis` despite different units — give each its own `y_axis` block (secondary one `alignment: 'right'`).

## Common pitfalls
### Error: "Invalid conditional expression. `filters` only accepts conditional expression in the following forms..."
**Typical mistake**: Putting a whole AQL expression as a filter operand. For example:
```aml
  PieChart {
    dataset: ecommerce
    calculation revenue {
      label: 'Revenue'
      formula: @aql order_items | sum(order_items.quantity * products.price);;
      calc_type: 'measure'
      data_type: 'number'
      model: ''
    }
    series {
      field: 'revenue'
    }
    conditions: [
      "order_items | sum(order_items.quantity * products.price) > 0", // left operand is a whole AQL expression
    ]
    settings {
      group_values_into: 10
    }
  }
```

**Fix**:
1. Declare the expression as a proper `calculation`
2. Use only the `calculation` name in the filter

```aml
  PieChart {
    dataset: ecommerce
    calculation revenue {
      label: 'Revenue'
      formula: @aql order_items | sum(order_items.quantity * products.price);;
      calc_type: 'measure'
      data_type: 'number'
      model: ''
    }
    series {
      field: 'revenue'
    }
    conditions: [
      "country.continent == 'Asia'",
      "revenue > 0",
    ]
    settings {
      group_values_into: 10
    }
  }
```
