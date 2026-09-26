# Worked-examples index

One row per example. Open `examples/<id>.md` for the full example (dataset fields, AQL, learning points).

**Columns:** `id` · `kind` (good/bad) · `analytic` (what it computes) · `problems` / `techniques` / `gotchas` (tag slugs; see `PROBLEMS.md`, `TECHNIQUES.md`, `GOTCHAS.md`).

**Lookup:** grep this file (or the example frontmatter) for a tag slug, or scan the `analytic` column, then open the matching `examples/<id>.md`.

| id | kind | analytic | problems | techniques | gotchas |
| --- | --- | --- | --- | --- | --- |
| 1 | good | Per-city average user count of each country | nested_aggregation | nested_aggregation |  |
| 2 | good | List 10 latest products | simple_listing | limit_sort |  |
| 3 | good | Top 10 products by price | top_n, data_type_mismatch | fn:rank, fn:cast |  |
| 4 | good | Top 10 countries by user count | top_n | fn:rank |  |
| 5 | good | Top 10 products with highest order count in last quarter, compare their order count in the same quarter of 3 previous years | top_n, period_compare | fn:relative_period, limit_sort |  |
| 6 | good | Top 10 products (dense ranking) with highest order count in last quarter, compare their order count in the same quarter of 3 previous years | top_n, period_compare | fn:top, fn:relative_period, fn:where, filter_by_subset, subset_as_table_metric |  |
| 7 | good | Top 10 products (dense ranking) with highest order count in last quarter, compare their order count in the same quarter of 3 previous years. Display product names and order counts | top_n, period_compare | fn:top, fn:relative_period, fn:where, filter_by_subset, subset_as_table_metric |  |
| 8 | good | List 10 latest products with at least 20 orders | filter_on_aggregate | dimensionalize_metric, limit_sort, explore_filters |  |
| 9 | good | Count of orders made on Thursdays (assuming week-start-day is Sunday) | date_part_filter | fn:date_part |  |
| 10 | good | Order count percentage of each product over total order count. Keep those whose percentage > 1% | ratio_percentage, filter_on_aggregate | fn:keep_grains, explore_filters |  |
| 11 | good | Order count percentage of each product over total order count. Use exclude_grains | ratio_percentage | fn:exclude_grains |  |
| 12 | good | List users together with their order count, their city's order count, their country's order count | simple_listing | dimensionalize_metric, use_existing_measure |  |
| 13 | good | Average age of users |  | fn:date_diff |  |
| 14 | good | Average age of users last month, compared with same month last year | period_compare | fn:relative_period, use_existing_measure, explore_filters |  |
| 15 | good | Average age of users over last 3 months, compare each with same month last year | period_compare | fn:relative_period, use_existing_measure, explore_filters | missing_date_trunc_with_relative_period |
| 16 | good | Average age of users each month, compared with the same period in previous year | period_compare | fn:relative_period, use_existing_measure, explore_filters | missing_date_trunc_with_relative_period |
| 17 | good | Trend of user sign-ups | growth_rate | window_navigation, use_existing_measure |  |
| 18 | good | Show the highest order count a user made in each year (excluding 2020) | nested_aggregation | nested_aggregation, explore_filters |  |
| 19 | good | Calculate the monthly average user sign-ups of each year | nested_aggregation | nested_aggregation |  |
| 20 | good | List users. Put their full name and city name in a single column. | simple_listing, multi_model_dim | custom_dim_on_many_side |  |
| 21 | good | List users. Put their full name and order count in a single column. | combine_metric_and_dim | combine_metric_and_dim, fn:cast |  |
| 22 | good | List orders with their revenue (value - discount). | combine_metric_and_dim, simple_listing | nested_aggregation, combine_metric_and_dim |  |
| 23 | good | List orders with their revenue (order's total price - discount). | combine_metric_and_dim, simple_listing | nested_aggregation, combine_metric_and_dim |  |
| 24 | good | Show order revenue (value - discount) by country. | combine_metric_and_dim | nested_aggregation, combine_metric_and_dim |  |
| 25 | good | Show monthly order revenue (value - discount). | combine_metric_and_dim | nested_aggregation, combine_metric_and_dim |  |
| 26 | good | Show monthly order revenue (value - discount). | arithmetics | custom_dim |  |
| 27 | good | List orders with their revenue (total price - discount, discount is applied on each item). | multi_model_dim | custom_dim_on_many_side |  |
| 28 | good | Average order value per city. | nested_aggregation | nested_aggregation, re_aggregate_existing_measure |  |
| 29 | good | Average order revenue per city. Revenue is total (price - discount), i.e. discount is applied on each item. | nested_aggregation, multi_model_metric | nested_aggregation, metric_on_many_side |  |
| 30 | good | Total user value in each city | simple_listing | use_existing_measure |  |
| 31 | good | Total user value in each city | simple_listing |  |  |
| 32 | good | List cities with user count | simple_listing |  |  |
| 33 | good | Cumulative total user value in each city over year | cumulative | fn:running_total, use_existing_measure |  |
| 34 | good | Total user value this year compared to last year | period_compare | fn:relative_period, use_existing_measure, explore_filters |  |
| 35 | good | Among the users in London, who are the top 10 users with most orders? | top_n_filtered | subset_as_table_metric, subset_by_row_filter, fn:rank, use_existing_measure, explore_filters |  |
| 36 | good | Among the users in London, who are the top 10 users with most orders? | top_n_filtered | subset_as_table_metric, subset_by_row_filter, fn:rank, explore_filters |  |
| 37 | good | Among the users in London, who are the top 10 users with most orders? | top_n_filtered | subset_by_row_filter, subset_by_aggregate_filter, filter_by_subset, fn:rank, use_existing_measure, explore_filters |  |
| 38 | good | Among the products whose price are greater than 100, which are the top 4 products with the highest prices? | top_n_filtered | fn:rank, subset_by_row_filter, explore_filters |  |
| 39 | good | List users who have made more than 100 orders of products whose price is greater than 10 | filter_on_aggregate | fn:where, use_existing_measure, explore_filters |  |
| 40 | good | List users who have made more than 100 orders of products whose price is greater than 10 | filter_on_aggregate | fn:where, explore_filters |  |
| 41 | good | Top 3 countries with most users created last month | top_n_filtered | fn:where, fn:rank, explore_filters |  |
| 42 | good | List the cities whose country has more than 100 user signed up last month. | filter_on_aggregate | fn:where, subset_by_aggregate_filter, subset_as_table_metric, filter_by_subset, explore_filters |  |
| 43 | good | List the countries that have at least 1 city with more than 100 users. | filter_on_aggregate | subset_by_aggregate_filter, subset_as_table_metric, filter_by_subset, explore_filters |  |
| 44 | good | List the most expensive product bought in each city | top_n_per_group | fn:rank, explore_filters |  |
| 45 | good | Top 3 most expensive products | top_n | fn:rank, explore_filters |  |
| 46 | good | Average order count of top 3 oldest users in each city | top_n_per_group, nested_aggregation | fn:rank, fn:date_diff, subset_by_aggregate_filter, subset_as_table_metric, filter_by_subset, nested_aggregation, re_aggregate_existing_measure, explore_filters |  |
| 47 | good | Total and Average order revenue of top 3 oldest users in each city. Revenue is price - discount (discount is applied on each item). | top_n_per_group, nested_aggregation, multi_model_metric | fn:rank, fn:date_diff, subset_by_aggregate_filter, subset_as_table_metric, filter_by_subset, nested_aggregation, metric_on_many_side, explore_filters |  |
| 48 | good | Average order revenue of top 3 oldest cities in each country. Revenue is price - discount (discount is applied on each item). Oldest cities are the cities with highest average user age. | top_n_per_group, nested_aggregation, multi_model_metric | fn:rank, fn:date_diff, subset_by_aggregate_filter, subset_as_table_metric, filter_by_subset, nested_aggregation, metric_on_many_side, explore_filters |  |
| 49 | good | Average order count of top 3 cities (with highest revenue) in each country. Revenue is price - discount (discount is applied on each item). | top_n_per_group, nested_aggregation, multi_model_metric | fn:rank, subset_by_aggregate_filter, subset_as_table_metric, filter_by_subset, nested_aggregation, metric_on_many_side, explore_filters |  |
| 50 | good | Average order count of top 3 cities (with highest revenue) in each country. Revenue is price - discount (discount is applied on each item). Use local metric filtering instead of explore filters. | top_n_per_group, nested_aggregation, multi_model_metric | fn:rank, subset_by_aggregate_filter, subset_as_table_metric, fn:where, filter_by_subset, nested_aggregation, metric_on_many_side |  |
| 51 | good | List users along with their third order dates | nth_per_group | fn:rank, fn:filter |  |
| 52 | good | List users along with their first and third order dates | nth_per_group | fn:rank, fn:filter |  |
| 53 | good | List users along with the total price of their first 3 orders and the total price of all orders. | nth_per_group | fn:rank, fn:filter |  |
| 54 | good | List users along with the price of their third order and the total price of all orders. | nth_per_group | fn:rank, fn:filter |  |
| 55 | good | Calculate user cohort retention over month | cohort_retention | dimensionalize_metric, fn:exclude_grains, fn:date_diff |  |
| 56 | good | List yesterday user reviews. Add a column to summary the review content. | inline_data_inference | ai_functions, custom_dim, explore_filters |  |
| 57 | good | List users who write reviews consistently. | time_gap_analysis | window_navigation, fn:date_diff, nested_aggregation, aggregate_on_window_function |  |
| 58 | good | List folders inside "Homework" | role_playing_relation | role_playing_via_model, explore_filters |  |
| 59 | good | List folders inside "Homework" | role_playing_relation | role_playing_via_lookup, subset_by_row_filter, subset_as_table_metric, filter_by_subset, explore_filters |  |
| 60 | bad | Top 3 most expensive products | top_n | fn:rank, explore_filters | rank_on_dim_not_metric |
| 61 | bad | Compare product prices | simple_listing |  | unaggregated_dim_in_explore_measures |
| 62 | bad | List cities with user count | simple_listing |  | unaggregated_dim_in_explore_measures |
| 63 | bad | List orders with their revenue (value - discount). | combine_metric_and_dim |  | combine_unaggregated_dim_with_metric |
| 64 | bad | List orders with their revenue (order's total price - discount). | combine_metric_and_dim | nested_aggregation | missing_pipe_precedence_parens |
| 65 | bad | List orders that belong to users who signed up in 2024. | simple_listing | explore_filters | manual_join_attempt |
| 66 | bad | Order count by user | simple_listing |  | double_aggregating_measures |
| 67 | bad | Average order revenue of top 3 oldest users in each city. Revenue is price - discount (discount is applied on each item). | nested_aggregation, top_n_per_group, multi_model_metric | fn:rank, fn:date_diff, subset_by_aggregate_filter, filter_by_subset, metric_on_many_side, explore_filters | double_aggregating_measures |
| 68 | bad | Total and Average order revenue of top 3 oldest users in each city. Revenue is price - discount (discount is applied on each item). | nested_aggregation, top_n_per_group, multi_model_metric | fn:rank, fn:date_diff, subset_by_aggregate_filter, filter_by_subset, metric_on_many_side, explore_filters, nested_aggregation | extra_dim_changes_explore_grain |
| 69 | bad | Average order count of top 3 cities (with highest revenue) in each country. Revenue is price - discount (discount is applied on each item). | nested_aggregation, top_n_per_group, multi_model_metric | fn:rank, subset_by_aggregate_filter, filter_by_subset, metric_on_many_side, explore_filters, nested_aggregation | wrong_inner_grain_in_nested_aggregation |
| 70 | bad | Top 10 products (dense ranking) with highest order count in last quarter, compare their order count in the same quarter of 3 previous years | top_n, period_compare | fn:top, fn:relative_period, fn:where, filter_by_subset, subset_as_table_metric, explore_filters | ranking_grain_mismatch |
