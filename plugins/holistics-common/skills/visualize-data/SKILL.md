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
1. Read the dataset with `fetch_dataset`. If the data needs AQL beyond the dataset's fields (new metrics, filters, period comparisons), write it with the [](../write-aql/) skill — WITHOUT visualization requirements.
2. Write the Viz yourself using the [](../viz/) skill's references: pick the viz type, place the fields, and apply the visualization requirements and default formatting.
3. `execute_viz` to run the viz and show the result to the user. Fix any errors it reports and re-run.

If the viz can't be made to work, fall back to showing a plain table with `execute_aql`.

Use `generate_viz` instead of step 2 when the user or the project's instructions (e.g. `CLAUDE.md`, `AGENTS.md`) ask for Holistics AI, or when the viz still fails after ~3 fix rounds. It needs an AQL explore; pass your last attempt and its errors. Unless the user asked for a viz type, let it pick one.

## Rules
* To visualize a plain table (no formatting, colors, etc.), you don't need a Viz — `execute_aql` is enough. Anything with formatting, conditional formatting, colors, or a chart type needs a Viz.
* To update date/time filters, change the AQL first (with [](../write-aql/)), then update the viz.
* Cohort retention should ALWAYS be visualized as Pivot Table.
* **Always** apply proper display formats to new percentage and currency dimensions/metrics.
  * Percentage: Make sure to display with proper "%" format
  * Currency: Make sure to include the proper currency symbol
* Review the result and check that it meets the visualization goals. Follow up to improve your visualizations if needed.
