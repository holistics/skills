# Official sources and evidence limits

Consult the relevant source before implementing a mapping. Product capabilities and converter coverage can change independently. Current tenant capabilities and installed validators take precedence over copied syntax examples.

## Holistics

- [Looker Migration Assistant Tool](https://docs.holistics.io/docs/from-others/looker/migration-tool): documents views, dimensions, and measures as supported, with a caveat that specific configurations within supported constructs may not fully convert. Lists Explores as not yet supported; dashboards, native derived tables, and Liquid references as unsupported. The inspected page documents no invocation interface and does not explicitly establish SQL-derived-table coverage. Confirm the actual tool/version before use; this skill supplies no converter executable or invented command.
- [Looker conceptual differences](https://docs.holistics.io/docs/from-others/looker/conceptual-differences): views/models, Explores/Datasets, dynamic roots, relationships, and connection configuration.
- [Explore migration](https://docs.holistics.io/docs/from-others/looker/explore-migration): dataset modeling, field selection, permissions, and feature comparison. A feature's target equivalent does not imply converter support.
- [Build relationships](https://docs.holistics.io/docs/relationships): many-to-many cannot be specified directly; junction models are a candidate design.
- [AML Relationship reference](https://docs.holistics.io/reference/aml/relationship): `many_to_one` and `one_to_one`, active paths, filter direction, nullability, and RLP propagation. Verify supported settings in the target version.
- [Relationships versus joins](https://docs.holistics.io/docs/joins/relationships-vs-joins): dynamic query planning, fanout handling, and Query Models for explicit SQL behavior.
- [Dynamic Query Model / Query Parameters](https://docs.holistics.io/docs/query-parameters): parameters inside model SQL and optional dashboard filter linkage.
- [Query Models](https://docs.holistics.io/docs/query-models): SQL models, filtering, and query parameters.

## Looker

- [LookML reference](https://docs.cloud.google.com/looker/docs/reference/lookml-quick-reference): authoritative entry point for source constructs, including dimensions, measures, joins, access rules, and persistence.
- [Join relationship](https://docs.cloud.google.com/looker/docs/reference/param-explore-join-relationship): source cardinality declarations. If page extraction is incomplete, consult the LookML reference rather than infer content from an empty response.
- [Understanding symmetric aggregates](https://docs.cloud.google.com/looker/docs/best-practices/understanding-symmetric-aggregates): reference for reviewing fanout-sensitive source behavior.
- [Templated filters and Liquid parameters](https://docs.cloud.google.com/looker/docs/templated-filters): predicates versus direct values, derived-table filtering, and persistence restrictions.
- [Liquid variable reference](https://docs.cloud.google.com/looker/docs/liquid-variable-reference): inspect the specific variable and its SQL, display, or user-context role.
- [`explore_source`](https://docs.cloud.google.com/looker/docs/reference/param-view-explore-source): native derived tables, filter binding, limits, sorting, timezone, and persistence constraints.
- [LookML dashboards](https://docs.cloud.google.com/looker/docs/reference/lookml-dashboard-overview): entry point for dashboard elements, filter/listener definitions, and source behavior.

## Research status

The skill combines an internal migration strategy brief (not stored in this repository) with the official migration-tool, conceptual-difference, relationship, Query Parameter, templated-filter, and native-derived-table documentation inspected during authoring. Other links are follow-up references, not evidence that every listed feature has been tested.

Dashboard/action equivalence, permission configuration, persistence, HTML formatting, and Ask AI metadata must be checked against current feature-specific documentation during a real migration. No customer LookML, warehouse results, converter execution, or restricted-user session was available when this skill was authored. The campaign fixture is synthetic.
