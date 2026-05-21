---
name: holistics-migrate-power-bi
description: Migrate a Power BI semantic model (TMDL + DAX) and reports to Holistics AMQL assets (AML models, datasets, dashboards, AQL/SQL metrics). Use this when converting a .pbix/.pbip project, translating DAX measures, mapping TMDL tables and relationships to Holistics models, or rebuilding Power BI reports as Canvas Dashboards.
---

## Instructions

This skill orchestrates a migration. It does **not** author AML/AQL by hand. All code authoring, validation, and querying goes through the Holistics CLI (`holistics aml ...`, `holistics mcp ...`) and the companion skills in the `holistics-development` and `holistics-reporting` plugins.

- **Prereqs:** load the [`setup-holistics-cli`](../../../holistics-development/skills/setup-holistics-cli) and [`setup-holistics-mcp`](../../../holistics-reporting/skills/setup-holistics-mcp) skills first. The CLI gives you `holistics aml validate` / `holistics aml compile` / `holistics sync-code`; the MCP gives you `search_docs`, `generate_aql`, `validate_aql`, `execute_aql`, `generate_viz`, `execute_viz`, `fetch_dataset`, `list_data_sources`, `read_data_source_table_schema`, `lookup_values`, `fetch_sample_data`.
- **Before writing anything**, load [`working-in-development`](../../../holistics-development/skills/working-in-development) for project prep, repo conventions, and the validate-as-you-go loop.
- **For every AML/AQL change**, defer to [`develop-amql`](../../../holistics-development/skills/develop-amql) (models, datasets, dashboards) and [`write-aql`](../../../holistics-development/skills/write-aql) (metrics). They wrap `generate_aql` / `validate_aql` correctly.
- **NEVER** guess AML keys, AQL function names, or operator semantics. Use `holistics mcp search_docs '{"question": "..."}'` (or call the `search_docs` MCP tool directly) before writing anything novel.
- **NEVER** hand-write AQL. Use `holistics mcp generate_aql '{"dataset_uname": "...", "query": "..."}'` (or the `write-aql` skill) with the original DAX, the model schema, and the business intent.
- **Validate every change** with `holistics aml validate <files>` after every edit, and re-run `holistics mcp validate_aql '{"aql": "...", "dataset_uname": "..."}'` for every metric.
- **Value parity** is non-negotiable: use `holistics mcp execute_aql` (or the `analyze-data` skill) to query Holistics and compare to Power BI for 5–10 dimension combinations per measure.
- Verify warehouse access before starting. Holistics runs live queries, so Excel and other file-only Power BI sources must land in a warehouse first (Postgres, BigQuery, Snowflake, Redshift, etc.). Use `holistics mcp list_data_sources '{}'` and `holistics mcp read_data_source_table_schema` to confirm the source landed correctly.
- Disable Power BI's "Auto date/time" before exporting `.pbip` so `LocalDateTable_*` artifacts do not appear in TMDL.

## When to use

- Converting a `.pbix` or `.pbip` project to a Holistics AMQL project.
- Mapping TMDL tables, columns, calculated columns, and relationships to AML models and dataset relationships.
- Translating DAX measures to AQL metrics (preferred) or SQL fallback measures.
- Rebuilding Power BI report pages as Holistics Canvas Dashboards.
- Reviewing a partially migrated project for parity issues.

## High-level workflow

Each phase calls out the **skills** and **CLI/MCP tools** to use.

| Phase        | Goal                                                                | Tools / Skills                                                                                                        |
| ------------ | ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| 0. Setup     | CLI + MCP ready, repo cloned, dev env selected.                     | `setup-holistics-cli`, `setup-holistics-mcp`, `working-in-development`.                                               |
| 1. Export    | `.pbix` → `.pbip` (text).                                           | Power BI Desktop.                                                                                                     |
| 2. Inventory | Catalogue tables, measures, relationships, pages, visuals, filters. | `rg`, `find`, `holistics mcp search_docs` for unknown Holistics concepts.                                             |
| 3. Warehouse | Land Power BI imports / M queries in the warehouse.                 | dbt or SQL views. Verify with `holistics mcp list_data_sources` + `read_data_source_table_schema`.                    |
| 4. Translate | Build models → relationships → dataset → metrics → dashboards.      | `develop-amql`, `write-aql`, `visualize-data`. Validate with `holistics aml validate` + `holistics mcp validate_aql`. |
| 5. Parity    | Run measure-value comparison vs Power BI.                           | `holistics mcp execute_aql`, `analyze-data`. See [](./references/validation.md).                                      |
| 6. Cleanup   | Lift visual-level filters, dedupe, document.                        | `develop-amql`, manual review.                                                                                        |
| 7. Sync      | Push to Holistics Cloud.                                            | `holistics sync-code`.                                                                                                |

## Translation order

Always migrate concepts in this order; each step depends on the previous one.

| #   | Power BI artifact                          | Holistics target                                                                      | Skill / Tool                                                                | Reference                              |
| --- | ------------------------------------------ | ------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- | -------------------------------------- |
| 1   | Power Query (M)                            | dbt or `.model.aml` (`type: 'query'`)                                                 | external dbt; `develop-amql` for query models                               | [](./references/migration-workflow.md) |
| 2   | Table (TMDL)                               | `.model.aml` (`type: 'table'` or `type: 'query'`)                                     | `develop-amql` + `holistics mcp read_data_source_table_schema`              | [](./references/tmdl-to-aml.md)        |
| 3   | Calculated column (DAX)                    | Dimension in the model/dataset (AQL preferred to SQL)                                 | `write-aql` + `holistics mcp generate_aql`                                  | [](./references/dax-to-aql.md)         |
| 4   | Relationships (active + `USERELATIONSHIP`) | Dataset `relationships { }` block                                                     | `develop-amql`                                                              | [](./references/tmdl-to-aml.md)        |
| 5   | Semantic model                             | `.dataset.aml`                                                                        | `develop-amql` + `holistics aml validate`                                   | [](./references/tmdl-to-aml.md)        |
| 6   | Measure (DAX)                              | `metric { definition: @aql ... ;; }` or `measure { definition: @sql ... ;; }`         | `write-aql` + `holistics mcp generate_aql` / `validate_aql` / `execute_aql` | [](./references/dax-to-aql.md)         |
| 7   | Report / Dashboard                         | `.page.aml` Canvas Dashboard                                                          | `visualize-data` + `holistics mcp generate_viz` / `execute_viz`             | [](./references/migration-workflow.md) |
| 8   | Alerts, subscriptions, embeds, share links | Holistics Alerts, Schedules, Embedded analytics, share links (manual or via REST API) | manual / REST API                                                           | [](./references/migration-workflow.md) |

## Core mental-model shifts

The most common translation patterns:

| DAX pattern                               | AQL replacement                                             |
| ----------------------------------------- | ----------------------------------------------------------- |
| `CALCULATE([m], filter)`                  | `m \| where(filter)`                                        |
| `CALCULATE([m], USERELATIONSHIP(...))`    | `m \| with_relationships(<aliased join path>)`              |
| `CALCULATE([m], SAMEPERIODLASTYEAR(...))` | `m \| relative_period(<timestamp>, interval(-1 year))`      |
| `CALCULATE([m], ALL(table))`              | `m \| of_all(<dim_or_model>)`                               |
| `CALCULATE([m], ALLEXCEPT(table, keep))`  | `m \| keep_grains(<keep_dim_or_model>)`                     |
| `DIVIDE(a, b)`                            | `safe_divide(a, b)`                                         |
| `IF / SWITCH`                             | `case(when:, then:, else:)`                                 |
| `RANKX`                                   | `rank(order: <metric> \| desc(), partition: <dim>)`         |
| Calculated table                          | Query model (`Model { type: 'query' … }`)                   |
| Marked Date table                         | Not required; period functions work on any timestamp column |

Full catalogue and AQL execution-order gotchas: [](./references/dax-to-aql.md).

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

- One Power BI semantic model → one `.dataset.aml`.
- One Power BI table → one `.model.aml`.
- One Power BI report → one `.page.aml`.

## Hard rules

- **Use the CLI + MCP for everything**: validation (`holistics aml validate`), AQL generation (`holistics mcp generate_aql`), AQL validation (`holistics mcp validate_aql`), warehouse introspection (`holistics mcp read_data_source_table_schema`), and live execution (`holistics mcp execute_aql`).
- **Never hand-write AQL**. Always go through `write-aql` / `generate_aql`, passing the original DAX and intent as context.
- **Never invent AML keys, AQL functions, or operator semantics**. Read [](./references/), then call `holistics mcp search_docs` to confirm.
- **Validate after every edit**: `holistics aml validate <files>` for AML; `holistics mcp validate_aql` for each metric.
- **Value parity over visual parity**: pick a measure, slice it across 5–10 dim combinations via `holistics mcp execute_aql`, and compare Power BI vs Holistics. Any difference must be zero or explained.

## Discovery commands

### Power BI source inventory

```bash
# Tables, measures, relationships
rg -l '^table ' <pbip>/<name>.SemanticModel/definition/tables
rg '^\s*measure ' <pbip>/<name>.SemanticModel/definition/tables -A 5
rg 'USERELATIONSHIP|CALCULATE|SAMEPERIODLASTYEAR|ALL\(|ALLEXCEPT|RANKX' <pbip>/<name>.SemanticModel -n

# Report pages and visuals
find <pbip>/<name>.Report/definition/pages -name '*.json'
```

### Holistics target inventory (via CLI / MCP)

```bash
# Confirm the warehouse source landed
holistics mcp list_data_sources '{}'
holistics mcp list_data_source_schemas '{"data_source_name":"<ds>"}'
holistics mcp read_data_source_table_schema '{"data_source_name":"<ds>","schema_name":"<schema>","table_name":"<table>"}'

# Inspect an existing dataset
holistics mcp list_datasets '{}'
holistics mcp fetch_dataset '{"dataset_uname":"<dataset>"}'

# Lookup canonical values for filters
holistics mcp lookup_values '{"dataset_uname":"<ds>","model_name":"<model>","dimension":"<dim>","lookup_conditions":[{"contain":"<text>"}]}'

# Validate the project
holistics aml validate models/**/*.aml datasets/**/*.aml dashboards/**/*.aml
```

### AQL authoring loop (per measure)

```bash
# 1. Generate from DAX + intent
holistics mcp generate_aql '{"dataset_uname":"<ds>","query":"<intent + DAX>"}'

# 2. Validate syntax + semantics
holistics mcp validate_aql '{"dataset_uname":"<ds>","aql":"<aql>"}'

# 3. Execute and compare to Power BI
holistics mcp execute_aql '{"dataset_uname":"<ds>","aql":"<aql>","title":"parity check: <measure>"}'
```

## Validation checklist (per dataset)

- `holistics aml validate` passes on every `.aml` (models, datasets, dashboards).
- Every metric passes `holistics mcp validate_aql`.
- All Power BI relationships are present in the dataset. Flag `true`/`false` for active/inactive. Example: `relationship(sales.customer_key > customer.customer_key, true)`.
- Every DAX measure has a metric or measure in Holistics.
- Sample value parity ≥ 99% across 10 dim-combinations, verified via `holistics mcp execute_aql` (see [](./references/validation.md)).
- Dashboard tab count matches; key visuals reproduce (`holistics mcp execute_viz`); filters are deduplicated.
- Final push: `holistics sync-code` to publish to Holistics Cloud.

## References

- [](./references/concept-mapping.md): Full Power BI ↔ Holistics concept table.
- [](./references/tmdl-to-aml.md): TMDL table, column, and relationship translation, including role-playing dimensions.
- [](./references/dax-to-aql.md): DAX pattern catalogue with AQL execution-order pitfalls and SQL fallbacks.
- [](./references/migration-workflow.md): End-to-end migration phases, manual-migration items, and definition of done.
- [](./references/validation.md): Three-layer parity testing strategy.
- Holistics docs: <https://docs.holistics.io/docs/from-others/power-bi/conceptual-differences>
- Holistics migration guide: <https://docs.holistics.io/docs/from-others/power-bi/migrating-to-holistics>
- Holistics CLI docs: <https://docs.holistics.io/docs/cli>

## Related skills

This plugin orchestrates skills from the `holistics-development` and `holistics-reporting` plugins. Load them on demand:

- `setup-holistics-cli` — install / authenticate the CLI; provides `holistics aml validate`, `holistics mcp`, `holistics sync-code`.
- `setup-holistics-mcp` — enable MCP tools (`search_docs`, `generate_aql`, `execute_aql`, `generate_viz`, etc.).
- `working-in-development` — repo conventions and the validate-as-you-go loop.
- `develop-amql` — author AML models, datasets, and dashboards.
- `write-aql` — generate AQL via `generate_aql`.
- `search-docs` — look up Holistics syntax and concepts.
- `visualize-data` — rebuild dashboards via `generate_viz` / `execute_viz`.
- `analyze-data` — run parity comparisons and explain result deltas.
