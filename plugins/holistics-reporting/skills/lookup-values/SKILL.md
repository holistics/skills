---
name: lookup-values
description: Verify the exact stored values of a field before filtering on them, guarding against case sensitivity, abbreviations, and typos. Use before writing any filter whose literal values you aren't 100% sure match the data.
---

# Verifying field values before filtering

Before you filter on a value, confirm it actually exists in the data in that
exact form. Filtering on a guessed literal ("Second-hand", "male", "VN") silently
returns wrong or empty results when the stored form differs.

## When to use
* Any filter on a dimension whose exact stored values you haven't confirmed.
* Especially categorical / text fields — and even "obvious" ones (a `gender`
  column can still hold unexpected values like "f", "m", "F", "M").

## How
1. Identify the field(s) most likely to carry the concept (check field names,
   labels, descriptions). Go from the most likely first.
2. List the matching values with case-insensitive "contains" patterns.
   **Batch 2–3 candidate patterns** in a single call to go faster.
3. Once you've identified the exact value(s), proceed to the real query. Don't
   keep using lookups to compute the answer — write the AQL.

## Command (swappable per scenario)
Default (Holistics) — tool `lookup_values`. A value matches if it contains any
of the patterns, case-insensitively:

```json
{
  "dataset_uname": "<dataset>",
  "model_name": "products",
  "dimension": "type",
  "lookup_conditions": [{ "contain": "second" }, { "contain": "used" }, { "contain": "sh" }]
}
```

`lookup_values` works on **text** dimensions only and returns at most 10 values,
so keep patterns precise. For other types, or to list every distinct value of a
small column, run an `explore` with [](../run-aql/) instead (`execute_aql` only
runs explores, not a bare `unique(...)` expression):

```aql
explore {
  dimensions { product_type: products.type }
  filters { products.type ilike '%second%' or products.type ilike '%used%' }
}
```

> Replace this command for other runtimes if needed. The guidance above is stable; only the command changes.

## If nothing matches
If you can't find the concept in any field, ask the user to clarify rather than
guessing a value.
