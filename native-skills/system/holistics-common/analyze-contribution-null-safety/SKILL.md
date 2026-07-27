---
name: analyze-contribution-null-safety
description: |-
  Null safety guidelines for analyze-contribution's calculations. ONLY use this skill when explicitly asked to do so.
user-invocable: false
---

### Null safety first
- `where()` in AQL returns null when no rows match — always wrap with `coalesce(..., 0)`
- `safe_divide` returns null when denominator is zero or either operand is null — always wrap with outer `coalesce(..., 0)`
- **Coalesce each additive component individually before any arithmetic.** Never add or subtract potentially-null values directly — `1 + null = null`, which silently nullifies the entire expression. For any metric with multiple components (e.g. numerator = A, denominator = A + B), always write `coalesce(A, 0) + coalesce(B, 0)`, not `A + B`. The outer `coalesce(safe_divide(...), 0)` is not sufficient on its own if any component feeding the denominator is null.
- Never compute `delta_value` from raw nullable values
- New segment detection: if `comparison_value_raw IS NULL` and `base_value_raw IS NOT NULL`, the segment is new in the base period — flag it in prose
- Disappeared segment detection: if `base_value_raw IS NULL` and `comparison_value_raw IS NOT NULL`, the segment disappeared in the base period — flag it in prose
- **Never omit any segment from the output.** Every segment that exists in either the base or comparison period must appear in the output (chart or table), regardless of whether its metric value is null, 0, or has data. A null or zero metric in one period is valid data — do not filter it out.
