# Concept mapping: Power BI ↔ Holistics

Full reference table. Use this during the inventory and translation phases.

## File-level

| Power BI | Holistics | Notes |
|----------|-----------|-------|
| `.pbix` (binary) | n/a | Convert to `.pbip` first via `File > Save As > Power BI Project`. |
| `.pbip` project | AMQL repository | Both are text-serializable; AMQL is uniform across all layers. |
| `<name>.SemanticModel/` | `models/` + `datasets/` | Power BI bundles tables and relationships together; Holistics splits them into models and a dataset. |
| `<name>.Report/` | `dashboards/` | One Power BI report maps to one or more `.page.aml` files. |
| `definition/database.tmdl` | n/a | Compatibility metadata; skip. |
| `definition/model.tmdl` | Dataset header / module | Culture and settings map to dataset metadata. |
| `definition/tables/*.tmdl` | `models/tables/*.model.aml` | One file per table. |
| `definition/relationships.tmdl` | `relationships { … }` block in `.dataset.aml` | Centralized in the dataset. |
| `definition/expressions.tmdl` (M) | Upstream SQL / dbt | Move ETL out of the BI tool. |
| `Report/definition.pbir` | Dataset reference in `.page.aml` | Manifest analog. |
| `Report/definition/pages/*/page.json` | `.page.aml` | One Holistics page per Power BI report page. |
| `Report/definition/pages/*/visuals/*/visual.json` | `chart` blocks inside `.page.aml` | Inline AMQL. |
| `Report/StaticResources/themes/*.json` | Dataset or dashboard theme settings | Re-create theme settings in AMQL. |

## Modeling

| Power BI | Holistics | Key difference |
|----------|-----------|----------------|
| Table (data-bearing, in VertiPaq) | `Model { type: 'table' … }` | A Holistics model is logical only and holds no data copy. |
| Calculated table (DAX) | `Model { type: 'query' … }` with `@sql select …` | Compiled at runtime. |
| Calculated column (DAX) | Dimension (AQL or SQL) inside the model | Compiled inline into SQL. |
| Column | Dimension | Defined as `dimension <name> { type, label, definition }`. |
| Measure (DAX) | Metric (AQL) or Measure (SQL) | Prefer an AQL metric for nested aggregation and period logic. |
| Hidden column | `hidden: true` on the dimension | |
| Format string | `format` on the dimension or metric | |
| Display folder | Dataset folder structure or model grouping | |
| Marked Date table | Not required | Period functions work on any timestamp column. |
| Role-playing dimension (multiple FKs to the same dimension) | Named join alias in `relationships { … }` | Each alias is a separate join path. |
| Active relationship | Default relationship in the dataset | |
| `isActive: false` relationship + `USERELATIONSHIP` | Named alias resolved via `with_relationships(...)` | |
| Bidirectional cross-filter | Many-to-many model or junction model | Holistics defaults to single-direction joins. |
| Row-level security (RLS) role | Dataset row-level permission | Different syntax; re-implement. |
| Calculation group | `metric` composition + dimension scope | Achieved via reusable metrics. |
| Field parameter | Parameter or variable in the dashboard | Re-create as a parameter. |

## Reporting

| Power BI | Holistics | Notes |
|----------|-----------|-------|
| Report | Canvas Dashboard (`.page.aml`) | One report may map to multiple pages. |
| Report page | `.page.aml` | One file per page. |
| Visual | `chart` block | Choose the visualization type explicitly. |
| Slicer | Filter block | |
| Bookmark | Dashboard parameter preset | Re-create manually. |
| Drill-through page | Canvas with parameter binding | |
| Tooltip page | Tooltip configuration on the chart | |
| Page-level filter | Page filter | |
| Visual-level filter | Chart filter (avoid; lift to page) | Apply DRY: deduplicate across visuals. |
| Report-level filter | Dataset filter or page filter | |

## Operational

| Power BI | Holistics | Notes |
|----------|-----------|-------|
| Workspace | Module | A Power BI workspace combines deployment and sharing; Holistics splits these into modules and permissions. |
| App | Published collection | Re-create the grouping. |
| Scheduled refresh | n/a (live queries) | No refresh required; data is always live. |
| Data alert | Holistics Alert | Re-create thresholds and recipients; bulk-create via REST API. |
| Email subscription | Schedule & email reports | Snapshot delivery. |
| Embed token / Publish to web | Embedded analytics | Reissue embed tokens or iframe URLs. |
| Share link | Shareable link | Generate fresh links and update any documentation that points to Power BI. |
| Fabric Git Integration | Native Git (GitHub, GitLab, Bitbucket) | |
| Deployment Pipelines | Dev/prod environments + PR merge | |
| Tabular Editor BPA | `holistics aml validate` + Validation API | |
| Power BI Service | Holistics Cloud (or self-hosted) | |
| DAX Studio | `execute_aql` or inline data preview | |

## Language

| DAX | AQL | Note |
|-----|-----|------|
| `SUM(Sales[Amount])` | `sum(sales.amount)` | Lowercase identifiers, dot notation. |
| `DISTINCTCOUNT(Sales[CustomerID])` | `count_distinct(sales.customer_id)` | |
| `COUNTROWS(Sales)` | `count(sales)` | |
| `DIVIDE(a, b)` | `safe_divide(a, b)` | |
| `AVERAGE(col)` | `avg(col)` | |
| `MIN/MAX(col)` | `min(col)` / `max(col)` | |
| `BLANK()` | `null` | |
| `IF(cond, a, b)` | `if(cond, a, b)` | |
| `SWITCH(TRUE(), …)` | `case when … then … end` (SQL) or nested `if` (AQL) | |
| `CALCULATE([m], <filter>)` | `m \| with_filter(<filter>)` | |
| `CALCULATE([m], ALL(t))` | `m \| with_filter(@aql 1=1)` resets scope | |
| `CALCULATE([m], USERELATIONSHIP(...))` | `m \| with_relationships(<alias path>)` | Use the named join alias. |
| `SAMEPERIODLASTYEAR(...)` | `m \| relative_period(<ts>, interval(-1 year))` | Works on any timestamp column. |
| `DATESYTD(...)` | `m \| to_date_period(<ts>, 'year')` | |
| `PARALLELPERIOD(...)` | `m \| relative_period(<ts>, interval(-n unit))` | |
| `RANKX` | `rank() over (order by …)` in SQL fallback | |
| `TOPN` | `\| top(n, <expr>)` (where supported) or SQL | |
| `VAR x = … RETURN …` | Composed AQL metrics or SQL CTE | Reuse via separate `metric` definitions. |
| Filter context (implicit) | Dimension scope (explicit) | Metrics declare scope, so there is no surprise re-evaluation. |
