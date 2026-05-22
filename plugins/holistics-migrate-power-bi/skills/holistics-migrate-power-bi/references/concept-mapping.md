# Concept mapping: Power BI ↔ Holistics

Reference table. Use this during the inventory and translation phases. Need more, use `search-docs` skill/tool.

## File-level

| Power BI                                          | Holistics                                   | Notes                                                                                                |
| ------------------------------------------------- | ------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `.pbix` (binary)                                  | n/a                                         | Convert to `.pbip` first via `File > Save As > Power BI Project`.                                    |
| `.pbip` project                                   | AMQL module                                 | Both are text-serializable; AMQL is uniform across all layers.                                       |
| `<name>.SemanticModel/`                           | `models/` + `datasets/`                     | Power BI bundles tables and relationships together; Holistics splits them into models and a dataset. |
| `<name>.Report/`                                  | `dashboards/`                               | One Power BI report maps to one or more `.page.aml` files.                                           |
| `definition/database.tmdl`                        | Data source                                 | skip.                                                                                                |
| `definition/model.tmdl`                           | Dataset header / module                     | Culture and settings map to dataset metadata.                                                        |
| `definition/tables/*.tmdl`                        | `models/tables/*.model.aml`                 | One file per table.                                                                                  |
| `definition/relationships.tmdl`                   | `relationships { }` block in `.dataset.aml` | Centralized in the dataset.                                                                          |
| `definition/expressions.tmdl` (M)                 | dbt / query model                           | Move ETL out of the BI tool.                                                                         |
| `Report/definition.pbir`                          | Dataset reference in `.page.aml`            | Manifest analog.                                                                                     |
| `Report/definition/pages/*/page.json`             | `.page.aml`                                 | One Holistics page per Power BI report page.                                                         |
| `Report/definition/pages/*/visuals/*/visual.json` | `chart` blocks inside `.page.aml`           | Inline AMQL.                                                                                         |
| `Report/StaticResources/themes/*.json`            | Dataset or dashboard theme settings         | Re-create theme settings in AMQL.                                                                    |

## Modeling

| Power BI                                           | Holistics                                          | Key difference                                                |
| -------------------------------------------------- | -------------------------------------------------- | ------------------------------------------------------------- |
| Table (data-bearing, in VertiPaq)                  | `Model { type: 'table' ... }`                      | A Holistics model is logical only and holds no data copy.     |
| Calculated table (DAX)                             | `Model { type: 'query' ... }` with `@sql select …` | Compiled at runtime.                                          |
| Calculated column (DAX)                            | Dimension (AQL or SQL) inside the model/dataset    | Compiled inline into SQL.                                     |
| Column                                             | Dimension                                          | Defined as `dimension <name> { type, label, definition }`.    |
| Measure (DAX)                                      | Metric (AQL) or Measure (SQL)                      | Prefer an AQL metric for nested aggregation and period logic. |
| Hidden column                                      | `hidden: true` on the dimension                    |                                                               |
| Format string                                      | `format` on the dimension or metric                |                                                               |
| Display folder                                     | Dataset folder structure or model grouping         |                                                               |
| Marked Date table                                  | Not required                                       | Period functions work on any timestamp column.                |
| Active relationship                                | Relationship in the dataset with `true` flag       |                                                               |
| `isActive: false` relationship + `USERELATIONSHIP` | Relationship with `false` flag; activate per metric via `with_relationships()` | See `dax-to-aql.md` for syntax.                              |
| Row-level security (RLS) role                      | Dataset row-level permission                       | Different syntax; re-implement.                               |
| Calculation group                                  | `metric` composition + dimension scope             | Achieved via reusable metrics.                                |
| Field parameter                                    | Parameter or variable in the dashboard             | Re-create as a parameter.                                     |

## Reporting

| Power BI            | Holistics                              | Notes                                     |
| ------------------- | -------------------------------------- | ----------------------------------------- |
| Report              | Canvas Dashboard (`.page.aml`)         | One report may map to multiple pages.     |
| Report page         | `.page.aml` (Tab)                      | One file per tab.                         |
| Visual              | `Viz` block                            | Choose the visualization type explicitly. |
| Slicer              | Filter block                           |                                           |
| Bookmark            |                                        | Re-create manually.                       |
| Drill-through page  | Dashboard with drill-through dashboard |                                           |
| Tooltip page        | Tooltip configuration on the chart     |                                           |
| Page-level filter   | Page filter                            |                                           |
| Visual-level filter | Chart filter (avoid; lift to page)     | Apply DRY: deduplicate across visuals.    |
| Report-level filter | Dataset filter or page filter          |                                           |

## Operational

| Power BI                     | Holistics                                 | Notes                                                                                                      |
| ---------------------------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Workspace                    | Module                                    | A Power BI workspace combines deployment and sharing; Holistics splits these into modules and permissions. |
| App                          | Published collection                      | Re-create the grouping.                                                                                    |
| Scheduled refresh            | n/a (live queries)                        | No refresh required; data is always live.                                                                  |
| Data alert                   | Holistics Alert                           | Re-create thresholds and recipients; bulk-create via REST API.                                             |
| Email subscription           | Schedule & email reports                  | Snapshot delivery.                                                                                         |
| Embed token / Publish to web | Embedded analytics                        | Reissue embed tokens or iframe URLs.                                                                       |
| Share link                   | Shareable link                            | Generate fresh links and update any documentation that points to Power BI.                                 |
| Fabric Git Integration       | Native Git                                |                                                                                                            |
| Deployment Pipelines         | Dev/prod environments + PR merge          |                                                                                                            |
| Tabular Editor BPA           | `holistics aml validate` + Validation API |                                                                                                            |
| Power BI Service             | Holistics Cloud                           |                                                                                                            |
| DAX Studio                   | `execute_aql` or inline data preview      |                                                                                                            |

## Language

| DAX                                    | AQL                                                                       | Note                                                          |
| -------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `SUM(Sales[Amount])`                   | `sum(sales.amount)`                                                       | Lowercase identifiers, dot notation.                          |
| `DISTINCTCOUNT(Sales[CustomerID])`     | `count_distinct(sales.customer_id)`                                       |                                                               |
| `COUNTROWS(Sales)`                     | `count(sales)`                                                            |                                                               |
| `DIVIDE(a, b)`                         | `safe_divide(a, b)`                                                       |                                                               |
| `AVERAGE(col)`                         | `avg(col)`                                                                |                                                               |
| `MIN/MAX(col)`                         | `min(col)` / `max(col)`                                                   |                                                               |
| `BLANK()`                              | `null`                                                                    |                                                               |
| `IF(cond, a, b)`                       | `case(when: cond, then: a, else: b)`                                      |                                                               |
| `SWITCH(TRUE(), …)`                    | `case(when: …, then: …, else: …)` (AQL) or `case when … then … end` (SQL) |                                                               |
| `CALCULATE([m], <filter>)`             | `m \| where(<filter>)`                                                    |                                                               |
| `CALCULATE([m], USERELATIONSHIP(...))` | `m \| with_relationships(<path>)`                                         | Use the named join alias.                                     |
| `SAMEPERIODLASTYEAR(...)`              | `m \| relative_period(<ts>, interval(-1 year))`                           | Works on any timestamp column.                                |
| `DATESYTD(...)`                        | `m \| period_to_date(<ts>, 'year')`                                       |                                                               |
| `PARALLELPERIOD(...)`                  | `m \| relative_period(<ts>, interval(-n unit))`                           |                                                               |
| `RANKX`                                | `rank(order: <metric> \| desc(), partition: <dimension>)`                 |                                                               |
| `TOPN`                                 | `top(n, <dimension>, by: <metric>, ...)`                                  |                                                               |
| `VAR x = … RETURN …`                   | Composed AQL metrics or SQL CTE                                           | Reuse via separate `metric` definitions.                      |
| Filter context (implicit)              | Dimension scope (explicit)                                                | Metrics declare scope, so there is no surprise re-evaluation. |
