---
name: migrating-looker-to-holistics
description: Guides Looker and LookML migrations to Holistics AMQL with the Migration Assistant first, then semantic redesign and validation. Use for migration planning, converting views, Explores, Looks or dashboards, reviewing Liquid or PDT gaps, and checking parity.
---

# Migrating Looker to Holistics

Convert supported, unambiguous definitions with deterministic tools first. Redesign semantic gaps, then validate Holistics behavior against Looker results.

## Guardrails

Preserve original LookML and customer evidence. Work on copies in an approved development environment. Keep source copies, converter output, exports, and the ledger outside sync/publish/Git-push directories. Only reviewed migration AML enters the target project. Holistics sync is bidirectional; `.gitignore` is not a boundary.

Record explicit authorization before hosted uploads, warehouse writes, production deployment, permission changes, code sync, publishing, or changed business semantics. Record unsupported items, never placeholders or silent omissions.

Before authoring, load `develop-amql` and `search-docs`; use `write-aql` for metrics. Load `setup-amql-development` if available; otherwise establish tooling and validators. Verify AML syntax against current docs or installed schemas and SQL expressions against the target dialect. Keep unresolved syntax, dialect-dependent expressions, and parameter behavior in Markdown notes, outside `.aml` files and dataset dependencies. AML compilation does not validate warehouse SQL. Mark authored but uncompiled AML `unverified`. Add no MCP server by default.

## Show results, then ask for decisions

Start from supplied files; request LookML only if unavailable. Work in small batches including all required dependencies. Start with the named report/Explore, or choose a representative slice and state why.

Show a useful partial result first: converted views with syntax-check evidence and outstanding Explore/dashboard gaps, or a source-backed assessment if conversion is blocked. Syntax checks do not establish parity; neither does a passing sample establish project-wide success.

Before asking:

1. Inspect source definitions, reports, documentation, usage history, and available Looker outputs.
2. Make reversible work choices within the guardrails; state consequential assumptions.
3. Ask one unresolved, blocking question with evidence, a recommendation, and its consequences.

Preserve established behavior when evidence agrees. Log pending decisions and continue independent work. Defer retirement, rollout, and broader acceptance questions until needed. Ask before acting if an authorization blocks even the first result.

## 1. Discover and record

Apply [the inventory checklist, contract questions, and mapping gates](reference/mapping.md) as objects enter each batch. Investigate first; the questions are not an opening questionnaire. Read referenced definitions to resolve includes, extends/refinements, constants, and dialects.

Keep one ledger row per source object or behavior, including each fully qualified field and dimension-group timeframe:

`source path/id | revision | dependencies | target | route | provenance | reason | owner decision | validation cases | evidence | status`

Routes: `deterministic candidate` requires documented converter coverage; `agent implementation` covers clear mappings outside that coverage; `design review` covers unresolved semantics; `blocked` names missing prerequisites. Provenance: converter name/version/run, `agent-authored`, or `not implemented`. A target equivalent does not establish converter support.

Statuses: `inventoried`, `converted`, `partially converted`, `failed`, `skipped`, `redesigned`, `validated`, `unverified`, `accepted deviation`, `retired (owner-approved)`.

Retain every row. Name owners for retirements and deviations; record missing access/evidence as blockers. Omit secrets and sensitive results.

Ledger invariant: compute source and ledger counts from enumerated IDs for views, fields/timeframes, Explores, dashboards, and tiles; report missing/extra IDs and resolve count mismatches before phase completion. Whole-model rows cannot replace field rows. A design note alone remains `inventoried`, not `partially converted`.

Completion: each inventoried item has a route and evidence or a blocker. Missing baselines block parity claims, not independent local conversion. Expand inventory across the agreed scope before handoff.

## 2. Convert eligible definitions

Auto-convert only when all hold:

- [current tool coverage](reference/sources.md) supports the construct and dialect; an easy mapping is not converter support;
- dependencies resolve without Liquid, context-sensitive logic, or unsupported inheritance;
- references, types, null handling, grain, and aggregate meaning have an unambiguous target;
- no access-enforcement change or unresolved semantic gap is involved;
- retainable source-to-target mapping and validation cases exist.

Candidates include table-backed views, column dimensions, and supported simple sums/averages at verified grain. Apply [measure review gates](reference/mapping.md#measures-that-require-review) before routing measures.

Verify the converter's version, interface, and data handling; never invent commands. For hosted conversion, authorize the destination and files first. Send only eligible files. Record files sent, input revision, options, warnings, and unsupported constructs. If unavailable, mark conversion blocked and continue other work.

Reconcile output field by field: primary keys, dimensions, every dimension-group timeframe, measures, hidden flags, SQL, value formats, and drill fields. Give missing or altered fields/properties their own review rows, including intentional timeframe consolidation.

Keep output snapshots immutable, named by tool version, revision, and run identifier. Edit a separate staging copy; transfer only reviewed AML into the project. Validate AML and inspect warnings/unresolved references.

Completion: every attempt is converted, partially converted, failed, or skipped with a reason. Compilation alone never yields `validated`.

## 3. Review semantic gaps

For each gap, record source behavior, why direct mapping fails, a Holistics pattern, tradeoffs, and a test exposing a plausible mistake. Obtain owner decisions for unresolved business meaning or changed semantics before implementation.

When sample data is available, calculate expected keyed totals and grouped rows independently in a disposable local engine. Exercise an approved candidate against those expectations before stopping for broader design decisions. Record commands, assertions, results, and untested cases. Missing Looker baselines block parity claims, not these local checks; label them source-semantic hypotheses.

Apply the relevant review:

- Derived tables: inspect LookML, not README labels. `derived_table: sql` maps to a Query Model; `explore_source` is a native derived table requiring Explore-aware redesign. For SQL-derived tables, review Liquid inputs, dialect, grain, persistence, and permissions separately from the model mapping.
- Liquid/parameters/filters: classify intent using [the Liquid review](reference/mapping.md#liquid-and-filter-review).
- Relationships: verify [target cardinalities](reference/mapping.md#cardinality). Reversing one-to-many notation does not preserve roots, joins, or filters. For many-to-many, profile both keys and bridge grain; consider junction models, separate facts with conformed dimensions, pre-aggregation, or metric redesign. A bridge alone does not prove correct sums/distinct counts.
- Keys: never disguise duplicates as one-to-one/many-to-one. Establish unique keys and document allocation/weighting for facts belonging to multiple categories. Test equal measure values on different fact keys: deduplicate by fact key, not `SUM(DISTINCT value)`.
- Query paths: compare dimension-only, metric-only, mixed-model, and filter-only queries under Holistics' dynamic root versus Looker's fixed root. Review custom/multi-condition joins, ambiguous/forced paths, nullability, filter direction, and row-level permission propagation. Fixed SQL may need a Query Model; record its loss of dynamic modeling flexibility.
- Metrics: reuse AML/AQL definitions and apply measure gates. Fanout handling does not prove symmetric-aggregate parity; test every affected metric at its grain.
- Restrictions: classify `sql_always_where`, `sql_where`, `always_filter`, and `always_join` as security, invariant restriction, or UI default. Keep SQL-enforced scope/join behavior at model/Query Model level unless an owner authorizes a change. Hidden fields are not column-level permissions.
- Persistence: verify PDT/datagroup triggers and freshness before choosing schedules. Review SQL-trigger invalidation and parameter-dependent persistence explicitly.
- Dashboards: stabilize metrics/relationships first, then use `build-dashboard` and `build-dashboard-controls`.

Completion: every gap has a reviewed implementation and discriminating tests, an owner-approved deviation, or a blocker.

## 4. Validate behavior

Require Looker-produced baselines: Look/Explore exports, API results, or Looker-generated SQL replayed verbatim with the same connection/user context. Record query/object ID, revision, extraction method, filters, user context, and timestamp. Agent-written SQL is a hypothesis, never a baseline. Post-SQL calculations and dashboard behavior need Looker-rendered outputs, not SQL replay alone.

Match snapshot, timezone, date range, user context, sorting, and limits. Without a shared snapshot, pin an upper date bound and record both timestamps; account for mutable/late-arriving data before claiming parity. Default to exact match. Record owner-approved tolerances before comparison; never relax them after seeing results. Record inputs, both outputs, and differences per case.

Check every affected dataset and acceptance-critical report:

- syntax: validate/compile AML and validate AQL; record tool, invocation, version, and result. Record `none` if unavailable, preventing `validated` status;
- generated SQL where available: sources, roots, joins, predicates, grain, partitions, null handling, and security; text need not match;
- values: compare report rows at the source grouping, including dimension keys, metric values, ordering, and limits; separately reconcile counts, totals/subtotals, and null groups. A matching total cannot prove matching grouped rows;
- filters: unfiltered, single, combined, cleared/default, multi-select, nonexistent values, and boundary dates;
- edge data: duplicate/null keys, unmatched dimensions, zero denominators, empty results, unequal group sizes;
- calculations: running totals/percent-of-total across ordering, partition, pivot, limits, hidden rows; previous periods at month/year boundaries and missing dates;
- interactions: per-tile filters, parameterized subqueries, cross-filters, drills/actions, and Look-linked replacements;
- security: positive/negative Viewer and Explorer tests, including exports, drills, suggestions, and alternate dataset paths. Missing/blank security attributes must fail closed. Admin tests do not prove row-level or column-level permissions;
- operations: freshness, parameter/cache isolation, cost, and latency against the contract.

Holistics results may cap at 1,000 rows. Use aggregate reconciliation or complete exports/pagination; capped results cannot prove full row counts.

Investigate mismatches. Mark intentional improvements `accepted deviation`, not parity. Missing Looker or restricted-user access leaves affected checks `unverified`.

Completion: critical cases pass or have named owner-approved deviations. Expose blockers/unverified checks; withhold unsupported equivalence claims.

## 5. Handoff

Deliver the ledger, converter provenance, designs, validation evidence, deviations, blockers, and proposed deployment/rollback steps. Separate completed agent work from customer decisions/access needed. Handoff authorizes neither sync nor publishing.

For Ask AI readiness, enrich descriptions, labels, supported tags, metric grain/denominators, synonyms, and custom/conversation context. Exclude sample rows, customer/member names, and restricted values. Test representative questions as restricted users: no listing, description, or aggregation of restricted fields/data. Metadata cannot repair semantics or replace permissions.

Completion: reconcile the full agreed scope. Every item has a final status with evidence or an explicit blocker. State what is validated, redesigned, and unsupported.
