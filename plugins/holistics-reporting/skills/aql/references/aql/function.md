AQL functions are the main building blocks of an AQL expression. They transform an input into an output based on specified arguments, and are typically combined using the [pipe operator](/reference/aql/operator#pipe).

This page is the entry point for all AQL functions. Each category below links to its own reference page with the full list of functions, their signatures, and examples.

| Category | What it does |
| --- | --- |
| [Table Functions](/reference/aql/table-function) | Transform a table expression into another table. `select`, `group`, `filter`, `unique`, `top`, `bottom`. |
| [Metric Functions](/reference/aql/metric-function) | Modify the context of a metric expression. Includes Condition, Relationship, LOD, Time-based, and Window functions. |
| [Aggregation Functions](/reference/aql/aggregator-functions) | Collapse multiple rows into a single value. SQL-equivalents of `SUM`, `COUNT`, `AVG`, plus statistical aggregates like `percentile_cont` and `stdev`. |
| [Logical Functions](/reference/aql/logical-functions) | Branch on conditions: `case`, `and`, `or`, `not`, `in`. |
| [Text Functions](/reference/aql/text-functions) | String manipulation: `concat`, `find`, `replace`, regex helpers, padding, case conversion. |
| [Time Intelligence Functions](/reference/aql/time-intelligence-functions) | Date/time helpers: truncation (`day`, `month`, `year`), formatting, unix conversion. |
| [AI Functions](/reference/aql/ai-functions) | LLM-powered helpers for classification, summarization, similarity. *Databricks and Snowflake only.* |
| [Null/Zero Handling Functions](/reference/aql/null-and-zero-functions) | `coalesce`, `nullif`, `safe_divide`. |
| [SQL Passthrough Functions](/reference/aql/sql-passthrough-functions) | Escape hatch to call native database functions when AQL doesn't cover what you need. |
| [Miscellaneous Functions](/reference/aql/miscellaneous-functions) | `cast`, `is_at_level`, and other one-offs. |

## See also

- [AQL Cheatsheet: Functions](/reference/aql/functions): flat alphabetical list to Ctrl-F
- [Operators](/reference/aql/operator): `==`, `+`, `between`, `like`, etc.
- [Pipe operator](/reference/aql/operator#pipe): how functions chain together
