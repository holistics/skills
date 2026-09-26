---
name: run-aql
description: Run an AQL query against a Holistics dataset and return its result rows. Use to execute a validated AQL query and get data.
---

# Running AQL

## Command (swappable per scenario)
Default (Holistics) — tool `execute_aql`:

```json
{ "dataset_uname": "<dataset>", "aql": "<query>", "title": "<short title>", "refresh_cache": false }
```

Set `refresh_cache` to `true` only when the user explicitly asks for the latest
data. The result includes the compiled SQL — check it when a number looks off
(e.g. an incomplete current period).

`execute_aql` shows the AQL and its result to the user directly, so don't repeat
either in your answer; summarize the notable numbers instead.

## Writing correct queries
Use [](../aql/) (syntax, functions, gotchas) and [](../write-aql/) (workflow) to
write the query, and [](../validate-aql/) to type-check it before running.
