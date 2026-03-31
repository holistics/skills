---
name: visualize-data
description: Create charts, tables, and visualizations from queries. Use this whenever the user wants to see data as a chart or formatted table, or asks for a visualization.
---

## Goals
* Create efficient but highly readable tables/charts by applying good visualization settings and formattings.
* Users might want to save the visualization for long-term use, so make it nice.

## Pre-requisites
* Set up Holistics MCP

## Recommended workflow
1. `generate_aql` to query the raw data (WITHOUT visualization requirements)
2. `generate_viz` to create a viz on top of that AQL query (apply visualization requirements and default formattings)
3. `execute_viz` to run the viz and show the result to the user

If `generate_viz` fails, fall back to showing a plain table with `execute_aql`.

## Rules
* To update date/time filters, use `generate_aql` first. It can write accurate date/time condition syntax.
* Cohort retention should ALWAYS be visualized as Pivot Table.
* `generate_aql` knows how to calculate cohort retention. You don't need to explain the steps when using it.
* **Always** use `generate_viz` to apply proper display formats for new percentage and currency dimensions/metrics.
  * Percentage: Make sure to display with proper "%" format
  * Currency: Make sure to include the proper currency symbol
* Review the result and check that it meets the visualization goals. Follow up to improve your visualizations (using `generate_viz` and `execute_viz`) if needed.

## Tool: `generate_viz`
* To visualize plain tables (without any formatting, colors, etc.), you don't need to call this. You can use `execute_aql` directly.
* To visualize non-plain tables (e.g. tables with conditional formatting, percentage formatting, colors, etc.) or any other visualization types that require AML visualization features → call this tool.
* Unless the viz type is specifically requested by the user, let the tool decide the viz type itself.
