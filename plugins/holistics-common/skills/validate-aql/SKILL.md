---
name: validate-aql
description: Validate an AQL query (or a single expression) against a Holistics dataset without running it. Use to type-check AQL before running or presenting it.
---

# Validating AQL

## Command (swappable per scenario)
Default (Holistics) — tool `validate_aql`:

```json
{ "dataset_uname": "<dataset>", "aql": "<query>" }
```

It returns `errors` (empty when valid) and `notes`. You can validate a
**single expression** (a metric, a filter, one calculation) — not only a whole
`explore`.

> Validation runs on Holistics, not on your local files. In the Development
> environment, keep `holistics sync-code --background` running so it sees your
> latest model/dataset edits (see the `setup-amql-development` skill).

## Writing valid queries
Use [](../aql/) (syntax, functions, gotchas) and [](../write-aql/) (workflow) to
write correct AQL and to fix whatever validation reports.
