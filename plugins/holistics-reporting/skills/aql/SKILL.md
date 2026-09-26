---
name: aql
description: Core AQL (Analytic Query Language) knowledge — syntax, semantics, functions, worked examples, and gotchas. Use whenever you need to write, read, or debug AQL yourself.
---

# AQL core knowledge

AQL is Analytic Querying Language for data analytics. This skill is
the knowledge base you consult while authoring AQL. It doesn't run queries — pair
it with actionable skills such as [](../write-aql/), [](../validate-aql/), etc.

## How to use these references
**AQL is not SQL — don't write it from general or SQL knowledge.** Read the core lessons *before* writing your first AQL; then pull in the specific per-function docs and examples your task needs (that part is on-demand — you needn't read everything).

1. **`references/aqlearn.md` — read this first, before writing any AQL.** The single, complete AQL lessons + rules + glossary reference (aggregation, dimensions/measures, level of detail, nested aggregation, window functions, ranking, relationships, SQL passthrough, …). Don't skip it — it holds the vital details you won't find by guessing, and reading it up front is faster than writing wrong AQL and fixing it.
2. **`references/aql/` — per-function reference docs.** Look up the exact
   syntax, semantics, and argument order for a specific function or operator.
   Files are named by function/operator (e.g. `sum.md`, `rank.md`, `where.md`);
   browse the folder and open the one you need. Use this to double-check — never
   assume a function, argument, or argument order.
3. **`references/examples/` — worked examples.** Follow proven patterns and
   avoid known pitfalls.
   * **Index** — `references/examples/INDEX.md` is a table with columns
     `id | kind | analytic | problems | techniques | gotchas` (`kind` is `good`
     or `bad`; the last three are tag slugs). To find examples, grep the index
     (or the example frontmatter) for a tag slug, or scan the `analytic` column;
     then open the matching `references/examples/<id>.md`.
   * **Example file** — `references/examples/<id>.md` has YAML frontmatter
     (`id`, `kind`, `analytic`, `problems`, `techniques`, `gotchas`) followed by
     `## Dataset fields` (```yaml), `## AQL` (```aql), and learning points.
   * **Tag glossaries** (same folder) define the slugs: `PROBLEMS.md` (how to
     frame the problem), `TECHNIQUES.md` (AQL idioms), `GOTCHAS.md` (pitfalls;
     entries marked `[silent]` fail with **no** validation error — a
     wrong-but-valid result — so look these up proactively).