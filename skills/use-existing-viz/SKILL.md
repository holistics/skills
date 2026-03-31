---
name: use-existing-viz
description: Search and use visualizations that already exist in the project to provide fast and curated data answers.
---

## NOTE
This is currently not available in Holistics Development environment.

## Pre-requisites
* Set up Holistics MCP

## Context
* "viz" or "viz blocks" refer to visualization blocks defined in Dashboards (.page.aml files)

## Search for existing viz
### When to search
* When a user asks a data question that requires querying data, call `search_viz_blocks` first to find reusable viz blocks before generating new AQL.

### Search strategy
* Extract key concepts from the user's question as search keywords (e.g., "sale", "customer", "retention", "product category").
  * Only use keywords, not natural language sentence.
* Consider synonyms and related business terms (e.g., "revenue" ↔ "sales", "churn" ↔ "retention").
* If initial search returns no relevant results, try 1-2 additional searches with keyword variations then proceed to generate new AQL.

## Evaluate viz blocks
* Multiple viz blocks may be returned. Scan their semantics to pick the most relevant ones. For example:
  * **Metrics and dimensions**: Does the AQL contain the measures and breakdowns the user is asking about?
  * **Grain**: Does the aggregation level match (e.g., daily vs. monthly, per-customer vs. per-region)?
  * **Filters**: If date filters are visible in the AQL, check for obvious mismatches with the resolved date range.

* Always inspect the AQL — don't rely on the viz block label and description alone.
* If no viz blocks returned, proceed to generate AQL.

## Validate and execute
* If a viz block looks relevant, MUST use tool `validate_viz_block_relevance` to check whether if it's truly relevant.

**If validation passes**: call tool `execute_viz_block` to show to result to user.
**If validation fails**: proceed to generate AQL (don't need to ask user for confirmation).

## Decision flow

1. Search for viz blocks.
2. Evaluate viz blocks by metadata/AQL.
3. Evaluate promising viz blocks relevance.
4. If valid → present to user.
5. If partially valid -> proceed with generate AQL with the viz block as a reference resource.
6. If invalid → proceed with generate AQL.
