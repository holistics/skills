---
name: analyze-contribution-query
description: |-
  Query and viz procedure for one analyze-contribution dimension — resolve sort direction, generate the AQL, generate the combo chart, execute it. ONLY use this skill when explicitly asked to do so.
user-invocable: false
---

## Inputs

| Input | Meaning |
|---|---|
| `metric` | Target metric being analyzed |
| `dimension` | The single dimension to break down by |
| `base_period_literal` | `@()` literal for the base period, verbatim from Phase 1 |
| `comparison_period_literal` | `@()` literal for the comparison period, verbatim from Phase 1 |
| `overall_delta_value` | Scalar overall delta from Phase 2 — used only to resolve sort direction |

Run this procedure for **one dimension at a time**. Never union or batch dimensions into a single query.

---

## Procedure

### 1. Resolve the sort direction

- `overall_delta_value < 0` (drop) → `sort_direction = 'asc'` (most negative first)
- `overall_delta_value > 0` (increase) → `sort_direction = 'desc'` (most positive first)

Use this value verbatim in both steps 2 and 3.

### 2. Generate the query (`generate_aql`)

You MUST use this prompt structure:

```
Calculate [metric] and its delta change (between [base_period] and [comparison_period]), broken down by [dimension].
Expected output:
- dimensions: [dimension]
- measures: base_period_metric, comparison_period metric, delta change
- filters: base period
- sorts: delta change [sort_direction]

NOTE: use /analyze-contribution-null-safety skill. Make sure to coalesce(metric, 0) on every metric.
```

### 3. Generate the viz (`generate_viz`)

You MUST use this prompt structure:

```
/analyze-contribution-generate-viz

sort_direction: [sort_direction]
```

### 4. Execute (`execute_viz`)

Call `execute_viz` with the generated viz.

---

## Output

Return to the caller:

- All artifacts (AQL, Viz, Explore) produced by the steps.

---

## Do not regress these

- `base_period_literal` and `comparison_period_literal` are used verbatim — never re-resolve or reformat them. `@()` literals must match the period granularity: `@(YYYY-MM-DD)` for days, `@(YYYY-WNN)` for weeks, `@(YYYY-MM)` for months, `@(YYYY-QN)` for quarters, `@(YYYY)` for years. Never use a day literal for a month or quarter period — it filters only a 2-day window, not the full period.
- One AQL query per dimension — never union or batch dimensions.
- Do not introduce volume weighting of any kind.
- Always mention `/analyze-contribution-null-safety` and `/analyze-contribution-generate-viz` in the generation prompts. They keep the generation accurate and efficient.