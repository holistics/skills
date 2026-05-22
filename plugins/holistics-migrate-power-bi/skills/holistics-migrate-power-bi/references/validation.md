# Validation: Power BI vs Holistics parity

Value parity is the only acceptable proof of a correct migration. Visual sign-off is necessary but not sufficient.

## Three layers of validation

```diagram
╭───────────────────╮   ╭─────────────────────╮   ╭──────────────────────╮
│ Syntax validation │──▶│ Per-measure parity  │──▶│ Dashboard sign-off   │
│ (always automated)│   │ (sampled, automated)│   │ (stakeholder review) │
╰───────────────────╯   ╰─────────────────────╯   ╰──────────────────────╯
```

## Layer 1 — Syntax validation

Run on every file before committing:

```bash
holistics aml validate models/tables/sales.model.aml
holistics aml validate datasets/aw_sales.dataset.aml
holistics aml validate dashboards/executive_summary.page.aml
```

Then run `holisitcs mcp validate_aql` for individual AQL snippets. CI should run `holistics aml validate` on every pull request.

## Layer 2 — Per-measure value parity

The goal is to confirm that a Holistics metric returns values identical to (or within tolerance of) the corresponding Power BI measure across a representative dim-combination sample.

### Sampling rules

- At least ten dim combinations per measure.
- Include: a total (no filter), one common dim filter, one date range, one role-playing-relationship slice if applicable, and one edge case (null, empty, or zero rows).
- For 50 or more measures, automate by scripting an export of Power BI values (DAX Studio → CSV) and a parallel `execute_aql` batch in Holistics.

### Tolerance

- Exact match for integer counts.
- ±0.01 absolute, or ±0.001% relative, for currency and decimal values (to handle floating-point drift).
- Any difference outside tolerance must be diagnosed, not papered over.

### Diagnostic checklist when values disagree

1. **Grain mismatch**: is the warehouse table at a different grain than the Power BI imported table? Check `count(*)` per source.
2. **Relationship path**: is the active or the aliased relationship being used? Inspect the compiled SQL via the Holistics query preview.
3. **Filter context**: does the metric include an unintended `where`? Strip filters one at a time.
4. **Time zone**: Power BI imports often coerce timestamps, while the warehouse may store UTC. Compare a single row's timestamp.
5. **Null handling**: DAX's `IF(ISBLANK(...), 0, ...)` vs SQL `coalesce`. Check whether nulls participate.
6. **Distinct count semantics**: `DISTINCTCOUNT` vs `count_distinct` over a different relational path can include or exclude different rows.
7. **Calculated column dependencies**: is the AML dimension recomputing on the correct grain?
8. **Source row count**: did the warehouse load drop rows due to a filter, dedup, or type-cast failure?

### Sample value-parity sheet

| Measure           | Filter / dim   | Power BI value | Holistics value | Δ     | Δ %   | Status |
| ----------------- | -------------- | -------------- | --------------- | ----- | ----- | ------ |
| Total Sales       | (none)         | 29,358,677.22  | 29,358,677.22   | 0.00  | 0.00% | ✅     |
| Total Sales       | Year=2024      | 9,127,442.10   | 9,127,442.10    | 0.00  | 0.00% | ✅     |
| Sales YoY %       | Year=2024      | 12.3%          | 12.3%           | 0.0pp | —     | ✅     |
| Sales by Due Date | Year=2024      | 8,994,107.55   | 8,994,107.55    | 0.00  | 0.00% | ✅     |
| Margin %          | Category=Bikes | 12.7%          | 12.7%           | 0.0pp | —     | ✅     |

Keep this sheet in the migration tracker (Linear, Notion, or the repo).

## Layer 3 — Dashboard sign-off

For each rebuilt page:

1. Capture a side-by-side screenshot of Power BI vs Holistics.
2. The owner confirms that the visual list matches, the filters behave the same, drill-through works, and KPI cards match.
3. Document any intentional differences (consolidated filters, removed redundant visuals).
4. The stakeholder approves in writing (PR comment, Linear ticket, or Slack thread).

## Spot-check script (pattern)

For each `(measure, filter-set)` row in the parity sheet:

1. Re-execute the DAX in Power BI (Performance Analyzer → copy DAX → DAX Studio → run with the same filters).
2. Re-execute the AQL in Holistics via `execute_aql` with the same filters.
3. Diff and log the result.

Automate this with a CSV of `measure, filter_json, expected_pbi_value` and a small script that loops `execute_aql`.

## Common failure modes (and where they originate)

| Symptom                                | Likely cause                                              | Fix                                                                                                  |
| -------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Holistics value is ~0                  | Wrong relationship alias used                             | Check `relationships { }` and the metric's `with_relationships(...)`.                                |
| Holistics value is too high            | Fan-out from a many-to-many join                          | Inspect the compiled SQL; restrict the join or use `count_distinct`.                                 |
| Holistics value is off by a date shift | Time zone or week-start mismatch                          | Confirm the warehouse timezone and the Holistics dataset timezone; check the `relative_period` unit. |
| YoY denominator is null                | `safe_divide` denominator is empty for the current period | Reproduce the prior-period metric in isolation and verify date coverage.                             |
| Calculated-column mismatch             | Dimension references the wrong field after a rename       | Confirm that `definition: @sql {{ … }}` paths match the warehouse column names.                      |
| Running total is flat                  | Missing date axis in the dashboard                        | Add a date dimension to the chart; `running_total` needs an ordering field.                          |

## Final acceptance criteria

- 100% of sampled measure-parity rows pass (within tolerance).
- 100% of rebuilt pages have sign-off.
- All `holistics aml validate` runs are green in CI.
- Manual-migration items (alerts, subscriptions, embeds, share links) are confirmed in Holistics by their owner.
