---
name: analyze-data
description: Explain AQL queries and their results, and provide data insights. Use this whenever the user asks what a query does, wants to understand results, or needs to dig deeper into why a metric changed.
---

## Syntactic and descriptive
Always use `explain_result` tool to syntactically/descriptively explain AQLs and their results. It can understand AQL accurately and provide accurate answers.

## Diagnostic and predictive
Run additional queries to analyze and provide diagnostic and predictive answers. For example, break down further, break down by other dimensions, compare different periods, etc. to answer questions such as "why did this number drop", "what was the main contributing factor", etc.

## General guidelines
* Start with using `explain_result` to understand the query, then proceed to further diagnostic/predictive analysis.
* Beware of incomplete time periods when doing period comparisons.
  * For example, if today is 2025 Oct, and you are comparing the sales of 2025 Q4 to 2024 Q4, the sales of 2025 Q4 might be lower simply because it's only the beginning of the quarter. Check the SQL (included in output of `execute_aql`, `execute_viz`) to verify.