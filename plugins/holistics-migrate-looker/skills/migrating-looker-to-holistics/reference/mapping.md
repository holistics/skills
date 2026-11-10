# Mapping and design-review gates

These mappings describe target design choices, not guaranteed converter coverage. Check current product documentation in [sources](sources.md).

## Inventory checklist

Account for each batch and its dependencies:

- includes, extends/refinements, constants, and connection dialects;
- views, primary keys, dimensions, dimension groups, measures, SQL and native derived tables;
- Explores, aliases, join conditions/types/cardinalities, forced joins, symmetric aggregates, and filter propagation;
- Liquid, parameters, filter-only fields, user attributes, access rules, and hidden fields;
- PDTs, datagroups, triggers, cache rules, schedules, freshness requirements, and external consumers of `publish_as_db_view`;
- LookML dashboards, user-defined dashboards, Looks and Look-linked tiles, merged queries, table calculations, filters/listeners, drills, actions, and extensions.

## Contract questions

Investigate these as objects enter a batch. Ask the owner one question at a time only when evidence leaves a blocking decision unresolved:

- Which reports, metrics, users, and drill paths are acceptance-critical? Check usage history before proposing retirement; lack of usage is not approval.
- What does one row represent in each fact, dimension, and bridge? Are primary keys unique and non-null in real data?
- Which Looker outputs are authoritative, and can their SQL, filters, timezone, user context, and data snapshot be captured?
- What are each metric's numerator, denominator, grain, weighting, and total/subtotal rules?
- Should dimension members without facts appear? Which fixed-root behavior is intentional?
- Which rules enforce security versus editable defaults? Who must see no rows or no columns?
- What freshness, cost, latency, deployment, and rollback requirements apply when those decisions arise?
- Does the owner permit semantic changes? Default to exact-match validation; obtain approval for any tolerance before comparison.

For SQL-control versus result filters and empty/multi-select/default behavior, apply [the Liquid and filter review](#liquid-and-filter-review).

## Object mappings

| Looker artifact | Holistics target | Gate or caveat |
| --- | --- | --- |
| Project | Workspace/module organization | Organizational mapping, not equivalent analytics behavior. |
| Table-backed `.view.lkml` | Table Model in `.model.aml` | Verify source, dialect, types, and keys. |
| SQL derived view `derived_table: sql` | Query Model | The target mapping is established; converter coverage is undocumented in the cited page. Use agent implementation when SQL semantics and syntax are verified; isolate unresolved Liquid inputs, dialect, grain, persistence, or permissions for design review. |
| Native derived table `explore_source` | Query Model or redesigned model/metric | Reproduce source Explore grain, filters/bindings, limits, sort, and timezone deliberately. |
| Dimension | Dimension | Simple column/reference conversion is a candidate; calculations require dialect and null checks. |
| `dimension_group` | Date/datetime dimension with date drill, date parts, time intelligence | Recreate only needed timeframes; check timezone, week start, fiscal calendars, and duration intent. |
| Basic measure | Model measure or dataset metric | Verify count versus count distinct, null behavior, grain, and fanout. |
| Filtered measure | AQL metric using `where` | Preserve filter scope and aggregation order. |
| Post-SQL measure/table calculation | AQL metric or visualization calculation | Review percent-of-total, running total, ordering, partition, pivots, and result limits. |
| HTML/Liquid display | HTML Format or dashboard/action behavior | Display-only formatting differs from SQL control; inspect each use. |
| Filter/parameter Liquid | Query Parameter, dashboard filter, or redesign | Classify intent before selecting a target. |
| Model file | No exact equivalent | Explores become Datasets; connections, access, caches, and persistence move to their owning systems. |
| Explore | Dataset | Dynamic root can change row inclusion, totals, joins, and null behavior. |
| Join / `sql_on` | Dataset relationship or Query Model | Simple verified many-to-one/one-to-one paths are candidates for modeling, not necessarily tool conversion. |
| One-to-many | Many-to-one with verified orientation | Recheck roots, nullability, filter flow, and metrics. |
| Many-to-many | Junction/bridge, fact redesign, pre-aggregation, or metric redesign | No direct many-to-many AML declaration; prove grain and allocation. |
| Symmetric aggregates | Holistics fanout handling plus verified model/metric design | Compare values; neither a bridge nor engine protection establishes parity alone. |
| `sql_always_where` / `always_filter` / `always_join` | Permissions, dataset/Query Model design, or dashboard defaults | Separate security and invariant restrictions from editable defaults. |
| Explore `fields:` / join `sql_where` | Dataset field selection / model or Query Model restriction | Preserve enforced SQL scope and outer-join row inclusion; an editable dashboard default needs owner approval. Field selection is not CLP. |
| `access_filter` / access grants / required grants | Permissions, RLP, CLP, resource sharing | Review attributes, propagation, hidden-field assumptions, and restricted users. |
| Datagroup / PDT / triggers | Query Model persistence and schedules where appropriate | SQL triggers and cache invalidation are not necessarily schedule-equivalent. |
| LookML dashboard | Dashboard as code/UI | Query tiles → VizBlocks; text → TextBlocks; filters → FilterBlocks. |
| User-defined dashboard / Look | Unified dashboards | Plan dashboard replacements for standalone Looks; verify current tenant equivalents before deciding. Inventory Look-linked tiles. |
| Dashboard filter / `listen` | FilterBlock with explicit interactions | Preserve per-tile scope; distinguish final filtering from derived-SQL inputs. |
| Dashboard element `filters:` | Viz-level filters in the VizBlock | Keep tile-local predicates separate from dashboard FilterBlocks; verify exact AML properties with the visualization schema. |
| Merged queries / extensions / auto-refresh / advanced filters | Explicit dashboard or model redesign | Record unsupported behavior and owner decisions. |
| Drill fields / links / actions | Drill-down, drill-through, actions, often dashboard layer | Test critical navigation and permission context. |
| Field picker groups / sets / aliases / suggestions / view labels | Dataset custom views where available, labels, descriptions, supported tags | Recreate intentionally; verify available organization controls in the tenant. |
| SQL-centric semantic definitions | Reusable AML/AQL semantic layer | Preserve approved behavior while making metric intent explicit. |
| Existing business descriptions | Semantic/reporting metadata and Ask AI context | Test answers; context quality is not a substitute for data validation. |

## Cardinality

Looker declares `one_to_one`, `many_to_one`, `one_to_many`, and `many_to_many`. Holistics AML declares `many_to_one` and `one_to_one`; verify the target version. A `direction: 'one_to_many'` setting, if present, describes filter propagation, not cardinality.

## Expression translation is context-sensitive

Looker `${TABLE}.column` commonly maps to Holistics `{{ #SOURCE.column }}`. Resolve `${field}` using the current `develop-amql` references for same-model versus cross-model scope instead of prescribing a bare replacement. Definitions use `definition: @sql` or `@aql` according to expression language. These fragments are not complete AML examples.

Resolve cross-view references, aliases, inherited definitions, quoting, dialect functions, and SQL-versus-AQL context before substitution. A global string replacement is not a LookML parser.

## Measures that require review

Route these measures to `design review`, even when a converter emits valid AML:

| Source measure | Check |
| --- | --- |
| `type: count` | Row count, primary keys, and symmetric aggregates. Counting a nullable column is not equivalent. |
| `count_distinct` | Distinct entity grain, nulls, and fanout. |
| Distinct aggregates with `sql_distinct_key` | Key uniqueness and the value counted once per key. |
| `type: number` over other measures | Aggregation order, nulls, and division by zero. |
| `filters:` expressions | Looker filter syntax, predicate placement, and aggregation scope. |
| Lists, percentiles, and yes/no measures | Dialect support and aggregate meaning. |

For post-SQL calculations, preserve partitioning, ordering, pivots, result limits, date boundaries, and denominator scope. The source may calculate over displayed rows rather than all warehouse rows.

## Liquid and filter review

Classify each occurrence by intent before choosing a target:

| Intent | Candidate target and check |
| --- | --- |
| Dynamic WHERE predicate | Query Parameter inside the Query Model. Preserve predicate placement and operators. |
| Scalar input | Typed parameter. Verify scalar support, allowed values, and empty/default behavior. |
| Dynamic SQL branch, field, table, or aggregate | Supported parameter branching or model/metric redesign. Allowlist identifiers and branches. |
| UI selector or dashboard filter | Dashboard control with explicit interactions. Verify which tiles and queries receive it. |
| Display formatting | HTML Format or dashboard/action layer. Preserve escaping and links. |
| Security/user attribute | Permissions and row/column-level policies. Editable filters cannot enforce security. |

Looker templated filters generate predicates; Liquid parameters can inject scalar values. Neither is interchangeable with a final-result tile filter.

Trace and test each dependency: `control → parameter/predicate → subquery → metric → tile`.

Check input behavior:

- capture empty/any-value behavior; an unfiltered Looker condition can render a true predicate such as `1=1`;
- translate range, wildcard, NOT, relative-date, and NULL filter expressions; passing Looker strings as scalars changes their meaning;
- verify multi-value parameter support in the target version;
- validate scalars against the agreed type/domain or allowed values, using supported escaping/binding;
- allowlist SQL identifiers and branches; never interpolate free text into identifiers or SQL fragments.
