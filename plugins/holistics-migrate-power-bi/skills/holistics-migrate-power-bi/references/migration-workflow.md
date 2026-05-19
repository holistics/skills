# End-to-end migration workflow

Use this as a checklist. Each step has a definition of done.

## Phase 0 — Prep on the Power BI side

1. **Save as `.pbip`**: in Power BI Desktop, choose `File > Save As > Power BI Project (*.pbip)`. Verify that `<name>.SemanticModel/definition/` contains TMDL files.
2. **Disable Auto date/time**: `File > Options > Current File > Data Load > Time intelligence`. Re-save. This removes `LocalDateTable_*` noise from TMDL.
3. **Snapshot source data**: capture a sample of source queries (M scripts) and the connected database or file source. Confirm that a warehouse target exists.
4. **Capture expected measure values**: for each top-level measure, screenshot the value across 5–10 dim combinations. This is the validation oracle.
5. **List manual-migration items** (alerts, subscriptions, embed URLs, share links). These are not stored in `.pbip`.

Done when: `.pbip` exists, no `LocalDateTable_*` tables remain, a warehouse target is identified, and the validation oracle has been captured.

## Phase 1 — Inventory

This is a read-only pass; do not write any AML yet.

1. List tables: `ls <pbip>/*.SemanticModel/definition/tables/`.
2. For each table, list every `column`, `measure`, `partition`, `hierarchy`, `isHidden`, `formatString`, and `displayFolder`.
3. Parse `relationships.tmdl`. Mark each relationship as active or `isActive: false`.
4. Parse `expressions.tmdl` and per-table partitions. Tag each M query as either "move upstream" or "represent as a query model".
5. List report pages: `ls <pbip>/*.Report/definition/pages/`.
6. For each page, enumerate visuals, page-level filters, slicers, and bookmarks.
7. Capture report-level concerns: theme, navigation, drill-through, tooltip pages.

Done when: a written inventory exists listing every Power BI artifact and its planned Holistics target.

## Phase 2 — Land sources in the warehouse

Holistics runs live queries, so Excel and other file sources must move to a warehouse.

1. Pick a warehouse that Holistics connects to (Postgres, BigQuery, Snowflake, Redshift, etc.).
2. For each M query, rewrite the transform as a SQL view or dbt model. Match the column names Power BI used (or document the rename map).
3. For each Excel sheet, upload as a table in the warehouse.
4. Verify that row counts and a few column sums match the Power BI in-memory tables.

Done when: every Power BI table has a corresponding warehouse table or view, and a row-count parity check passes.

## Phase 3 — Translate models

Translate in this order: table → calculated column → relationship → dataset → measure.

1. **Models** (`models/tables/*.model.aml`): one per Power BI table. Apply the mapping in [](./tmdl-to-aml.md). Use `read_data_source_table_schema` to fetch exact column types and names.
2. **Calculated columns** become dimensions inside the model.
3. Run `holistics aml validate` on each model.

Done when: every Power BI table has a `.model.aml` that validates.

## Phase 4 — Build the dataset

1. Create `datasets/<name>.dataset.aml`.
2. List every model in `models: [...]`.
3. Translate relationships:
   * Active Power BI relationships become default relationship tuples.
   * Inactive Power BI relationships used by `USERELATIONSHIP` measures become named join aliases.
4. Validate the dataset.

Done when: `holistics aml validate` passes on the dataset, and `fetch_dataset` shows every expected model and relationship.

## Phase 5 — Translate measures

For each Power BI measure (work in dependency order, base measures first):

1. Read the full DAX, including any referenced sub-measures.
2. Classify the measure using the patterns in [](./dax-to-aql.md).
3. Call `generate_aql` with the DAX, the intent, and the relevant dimensions.
4. Place the metric in the appropriate model or dataset scope.
5. Run `validate_aql`, then sample-execute via `execute_aql` and compare to the Power BI oracle.

Done when: every measure with a DAX equivalent has a metric or measure in Holistics, and the value-parity check passes (see [](./validation.md)).

## Phase 6 — Rebuild dashboards

1. One Power BI report page → one `.page.aml`.
2. For each visual, pick the closest Holistics chart type (use `generate_viz`).
3. Filters: lift any visual-level filter that repeats across two or more visuals to page-level; lift any page-level filter shared across pages to dataset-level.
4. Bookmarks become dashboard parameter presets.
5. Drill-through pages become canvases with parameter binding.
6. Theme: re-apply colors and fonts via dashboard theme settings.
7. Validate each `.page.aml`.

Done when: every Power BI report page has a Holistics page, the key visuals reproduce, and filters are deduplicated.

## Phase 7 — Manual migration (outside `.pbip`)

These items cannot be extracted from TMDL or JSON and must be re-created from scratch:

| Power BI feature | Holistics action |
|------------------|------------------|
| Data alerts | Re-create thresholds and recipients in Holistics Alerts (bulk via REST API for ten or more). |
| Scheduled refresh | Not needed (live queries). Replace email subscriptions via Schedule & email reports. |
| Email subscriptions | Schedule & email reports for snapshot delivery. |
| Embed in app / Publish to web | Reissue embed tokens and iframe URLs via Holistics Embedded analytics. |
| Share links | Generate fresh links and update any documentation that points to Power BI URLs. |
| Workspace roles | Re-implement via Holistics permissions on modules. |
| RLS roles | Re-implement as Holistics row-level permissions. |

Done when: every alert, subscription, embed, and share link from the inventory has an active Holistics equivalent.

## Phase 8 — Cutover

1. Run side-by-side validation for one or two sprint cycles. Owners verify a sample of dashboards each.
2. Update internal documentation and portal links to point to Holistics.
3. Communicate the cutover date and set the Power BI workspace to read-only.
4. After cutover, freeze the Power BI workspace and keep it as a historical reference for 30–90 days.

Done when: stakeholders sign off, links are updated, and the Power BI workspace is read-only.

## Definition of done (whole migration)

* All `.model.aml`, `.dataset.aml`, and `.page.aml` files validate with `holistics aml validate`.
* Value parity is ≥ 99% on at least ten measure × dim-combination samples per dataset.
* Every report page has a corresponding Holistics page; visual count matches within 10%.
* All manual-migration items (alerts, subscriptions, embeds, share links) are reissued.
* Stakeholder sign-off is recorded.
* The Power BI workspace is frozen or read-only.
