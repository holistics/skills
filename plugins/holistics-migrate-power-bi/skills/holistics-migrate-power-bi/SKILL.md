---
name: holistics-migrate-power-bi
description: Migrate a Power BI semantic model (TMDL + DAX) and reports to a Holistics AMQL project (AML models, datasets, dashboards, AQL/SQL metrics). Use this when converting a .pbix/.pbip project, translating DAX measures, mapping TMDL tables and relationships to Holistics models, or rebuilding Power BI reports as Canvas Dashboards.
---

## Instructions
* Install the `holistics-development` plugin alongside this one. This skill defers to its `develop-amql`, `write-aql`, `search-docs`, `visualize-data`, and `working-in-development` skills for all code authoring.
* Use the `working-in-development` skill to prepare for the development.
* **NEVER** assume any AML/AQL syntax, functions, or references. Use `develop-amql` and `write-aql` to author code.
* Verify warehouse access before starting. Holistics runs live queries, so Excel and other file-only Power BI sources must land in a warehouse first (Postgres, BigQuery, Snowflake, Redshift, etc.).
* Disable Power BI's "Auto date/time" before exporting `.pbip` so `LocalDateTable_*` artifacts do not appear in TMDL.
* Always run `holistics aml validate` on every new or edited `.model.aml`, `.dataset.aml`, and `.page.aml` before considering a task complete.
* Always validate measure values with a value-parity check against Power BI before sign-off.

## When to use
* Converting a `.pbix` or `.pbip` project to a Holistics AMQL project.
* Mapping TMDL tables, columns, calculated columns, and relationships to AML models and dataset relationships.
* Translating DAX measures to AQL metrics (preferred) or SQL fallback measures.
* Rebuilding Power BI report pages as Holistics Canvas Dashboards.
* Reviewing a partially migrated project for parity issues.

## High-level workflow
1. **Export to text.** In Power BI Desktop: `File > Save As > Power BI Project (*.pbip)`. This exposes the semantic model as TMDL.
2. **Inventory.** Read TMDL, DAX, M, and report JSON without writing anything. Catalogue tables, columns, relationships (active and inactive), measures, calculated columns, M queries, report pages, visuals, page-level and visual-level filters, and bookmarks.
3. **Land sources in the warehouse.** Move heavy Power Query (M) ETL upstream into SQL views or dbt models. Verify row counts match the Power BI imported tables.
4. **Translate per concept** in the order below. See [](./references/concept-mapping.md).
5. **Validate measure parity** on a sample of ten or more dim-combinations per measure. See [](./references/validation.md).
6. **Rebuild reports** as Canvas Dashboards. Lift repeated visual-level filters to page-level or dataset-level.

## Translation order
Always migrate concepts in this order; each step depends on the previous one.

| # | Power BI artifact | Holistics target | Reference |
|---|-------------------|------------------|-----------|
| 1 | Power Query (M) | Upstream SQL / dbt | [](./references/migration-workflow.md) |
| 2 | Table (TMDL) | `.model.aml` (`type: 'table'` or `type: 'query'`) | [](./references/tmdl-to-aml.md) |
| 3 | Calculated column (DAX) | Dimension in the model (AQL definition preferred, SQL fallback) | [](./references/dax-to-aql.md) |
| 4 | Relationships (active + `USERELATIONSHIP`) | Dataset `relationships { … }` block + named join aliases | [](./references/tmdl-to-aml.md) |
| 5 | Semantic model | `.dataset.aml` | [](./references/tmdl-to-aml.md) |
| 6 | Measure (DAX) | `metric { definition: @aql … }` or `measure { definition: @sql … }` | [](./references/dax-to-aql.md) |
| 7 | Report page / visual | `.page.aml` Canvas Dashboard | [](./references/migration-workflow.md) |
| 8 | Alerts, subscriptions, embeds, share links | Holistics Alerts, Schedules, Embedded analytics, share links (manual or via REST API) | [](./references/migration-workflow.md) |

## Core mental-model shifts
DAX relies on an implicit filter context and an in-memory VertiPaq engine. AQL uses an explicit dimension scope and pushes SQL down to the warehouse. The most common translation patterns:

| DAX pattern | AQL replacement |
|-------------|-----------------|
| `CALCULATE([m], filter)` | `m \| with_filter(filter)` |
| `CALCULATE([m], USERELATIONSHIP(...))` | `m \| with_relationships(<aliased join path>)` |
| `CALCULATE([m], SAMEPERIODLASTYEAR(...))` | `m \| relative_period(<timestamp>, interval(-1 year))` |
| `DIVIDE(a, b)` | `safe_divide(a, b)` |
| `ALL(table)` | `m \| with_filter(@aql 1 = 1)` (or explicit dimension scope) |
| Calculated table | Query model (`Model { type: 'query' … }`) |
| Marked Date table | Not required; period functions work on any timestamp column |

Full catalogue: [](./references/dax-to-aql.md).

## Recommended project layout
```
holistics-project/
├── models/
│   ├── tables/
│   │   ├── sales.model.aml
│   │   ├── customer.model.aml
│   │   └── …
│   └── queries/
│       └── active_users.model.aml
├── datasets/
│   └── aw_sales.dataset.aml
└── dashboards/
    ├── executive_summary.page.aml
    └── …
```

* One Power BI semantic model → one `.dataset.aml`.
* One Power BI table → one `.model.aml`.
* One Power BI report → one or more `.page.aml`.

## Hard rules
* Never hand-write AQL. Use `generate_aql` via the `write-aql` skill, passing the original DAX and intent as context.
* Never invent AML keys or functions. Use `search_docs` via the `search-docs` skill, or read [](./references/) first.
* Always run `holistics aml validate` on each new or edited file before claiming the task is done.
* Always validate measure values. Pick a measure, slice it across 5–10 dim combinations, and compare Power BI vs Holistics. Any difference must be zero or explained.
* Role-playing dimensions (multiple FKs from a fact to the same dimension) translate to explicit join aliases in the dataset, not to `USERELATIONSHIP` calls.
* Visual-level filters repeated across visuals should be lifted to page-level or dataset-level filters.

## Discovery commands during inventory
```bash
# Tables, measures, relationships
rg -l '^table ' <pbip>/<name>.SemanticModel/definition/tables
rg '^\s*measure ' <pbip>/<name>.SemanticModel/definition/tables -A 5
rg 'USERELATIONSHIP|CALCULATE|SAMEPERIODLASTYEAR' <pbip>/<name>.SemanticModel -n

# Report pages and visuals
find <pbip>/<name>.Report/definition/pages -name '*.json'
```

## Validation checklist (per dataset)
* `holistics aml validate` passes on every `.model.aml`, `.dataset.aml`, `.page.aml`.
* All active Power BI relationships are present in the dataset.
* All inactive (`isActive: false`) Power BI relationships are represented as named join aliases.
* Every DAX measure has a metric or measure in Holistics.
* Sample value parity ≥ 99% across 10 dim-combinations (see [](./references/validation.md)).
* Dashboard page count matches; key visuals reproduce; filters are deduplicated.

## References
* [](./references/concept-mapping.md): Full Power BI ↔ Holistics concept table.
* [](./references/tmdl-to-aml.md): TMDL table, column, and relationship translation, including role-playing dimensions.
* [](./references/dax-to-aql.md): DAX pattern catalogue with AQL and SQL fallback equivalents.
* [](./references/migration-workflow.md): End-to-end migration phases, manual-migration items, and definition of done.
* [](./references/validation.md): Three-layer parity testing strategy.
* Holistics docs: <https://docs.holistics.io/docs/from-others/power-bi/conceptual-differences>
* Holistics migration guide: <https://docs.holistics.io/docs/from-others/power-bi/migrating-to-holistics>

## Related skills
This plugin pairs with the `holistics-development` plugin, which provides the code-authoring skills used throughout the workflow:
* `develop-amql` — author AML models, datasets, and dashboards
* `write-aql` — generate AQL via `generate_aql`
* `search-docs` — look up Holistics syntax and concepts
* `visualize-data` — rebuild dashboards
* `working-in-development` — prep for AMQL development
