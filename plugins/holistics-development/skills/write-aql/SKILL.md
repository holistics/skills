---
name: write-aql
description: Write and run AQL (Analytic Query Language) queries to answer data questions. Use this whenever the user asks for data, wants to query a dataset, needs to filter/aggregate/join data, or asks about metrics and dimensions in Holistics.
---

## Pre-requisites
* Set up Holistics MCP

## Writing AQL
* Always use `generate_aql` tool to write AQLs instead of writing yourself. It can understand the question well and write accurate queries.
* In your natural language query:
  * Provide all relevant data context (e.g. sample data, past errors) to improve the tool's accuracy and relevance.
  * Quote filter values if (and only if) you know the exact values to filter (e.g. "Vietnam", "VN", `England`).
* Always leverage previous tool call results as reference resources:
  * This enables reuse of existing metric/measure definitions rather than regenerating them from scratch.
  * Even partially relevant AQLs are valuable — they may contain reusable measures, metrics, or filters that apply to the new query.
* When working with unknown data structures (such as structs, JSONs, or ambiguous fields like "settings", "configs"), you **CANNOT** simply ask `generate_aql` to query them, and **NEVER** assume or guess their properties and structures. Otherwise, `generate_aql` may use INACCURATE or NON-EXISTING properties. In this case, run one query to preview and inspect the data structure first, then write another query for the actual answer.

  Example recommended workflow:
  * User question: List users who have spell check enabled
  * Step 1: `generate_aql`: List 10 latest users with their settings
  * Step 2: `execute_aql` and check the result for data shape of user settings
  * Step 3: `generate_aql`: List users who have spell check enabled (by checking their settings). Example of `users.settings`: `{"enable_spell_check": true, "theme": 3}`
    * NOTE: **ALWAYS** provide the data schema or example if it's not already available in dataset. It is **MORE USEFUL** than only providing the json path.
  * Step 4: `execute_aql` and provide answer

## Tool: `generate_aql`
* In your natural language query, do NOT put filter values in quotes unless you are absolutely certain the filter values are exactly accurate. If you quote uncertain filter values, it can result in wrong filtering due to case sensitivity and typos.
* AQL does NOT have visualization features such as "highlight", "% format", "color", "column chart", but Viz AML DOES. => You MUST OMIT the visual stuff (like "highlight" or "color") from the `query` for `execute_aql`, and provide them to `generate_viz` INSTEAD.

## Tool: `execute_aql`
* IMPORTANT: Prefer visualizations (using `generate_viz` + `execute_viz`) to plain tables (using `execute_aql`) whenever **appropriate**. E.g. always use `generate_viz` + `execute_viz` for Cohort Retention because otherwise it would be very hard for the user to read the plain data table.
* Always try to provide a summary with highlightable data/numbers (or even short insights) for the result. But do NOT repeat the result in your answer.
* Remember that `execute_aql` tool shows the AQL and its result directly to the user. You should not repeat the AQL in your answer.
* If the AQL comes from past conversations, ALWAYS mention the past conversations in your final answer.

## Related skills
* Writing and executing AQL only return plain table data. To retrieve visualized data (e.g. pivot tables, column charts), use [](../visualize-data/) skill.
