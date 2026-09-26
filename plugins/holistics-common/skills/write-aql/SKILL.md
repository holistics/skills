---
name: write-aql
description: Write and run AQL (Analytic Query Language) queries to answer data questions. Use this whenever the user asks for data, wants to query a dataset, needs to filter/aggregate/join data, or asks about metrics and dimensions in Holistics.
---

# Writing AQL to answer a question

Goal: turn the user's analytics request into a correct AQL query, verify it, and
run it.

> **AQL is not SQL.**  Writing it from SQL habits or memory produces wrong queries and burns validate→fix cycles.
> **Read the [](../aql/) references _before_ you write — not after you fail.**
> Looking things up first is faster than guessing and retrying.

> **Prefer delegating to a sub-agent (to save context).** Reading the AQL references consumes context. If an `aql-writer` sub-agent is available, hand the request to it and let it do the lookups + write/validate — it returns only the final AQL, keeping your main context lean. Otherwise, if your runtime has a generic task/subagent tool, spawn one and tell it to use the `aql`, `write-aql`, and `validate-aql` skills. If neither is available (e.g. claude.ai, ChatGPT), or you *are* the `aql-writer` sub-agent, do the work yourself.

## Who writes the AQL
By default, **write it yourself** with the workflow below.

Delegate to Holistics AI (`generate_aql`) instead — see *Delegating to Holistics AI* — when the user asks for Holistics AI / `generate_aql`, or the project's instructions (e.g. `CLAUDE.md`, `AGENTS.md`) say to use it.

## Prerequisites
* Set up Holistics MCP
* Know the dataset. Use `fetch_dataset` to list its models, fields, and metrics — that's your `dataset_fields`. Use only those, with their **EXACT** names. In an AMQL repo, also read the dataset/model `.aml` files for definitions and descriptions.

## Workflow
1. **Understand the request** against the available fields. If you genuinely can't (no matching fields, ambiguous business logic, or it's not an analytic), ask the user to clarify instead of guessing.
2. **Read the AQL references first — required, before writing anything.** Don't write AQL from memory or SQL intuition. Via the [](../aql/) skill:
   * Read `references/aqlearn.md` (the core lessons/rules) if you haven't yet this session.
   * Look up the exact functions/operators you'll use in `references/aql/`.
   * For nested aggregation, top-N-per-group, period comparison, level-of-detail, cohort retention, or ranking — study the worked examples and gotchas in `references/examples/`. Always check the `[silent]` gotchas: they produce wrong-but-valid AQL with **no** validation error, so validation won't catch them for you.
3. **Verify filter values before using them.** If the request filters on values you're not certain match the stored data (case, abbreviations, typos), use [](../lookup-values/) first. Never assume filter literals are exact.
4. **Inspect opaque fields.** For structs / JSON / "settings"-type fields, never guess the structure — run a preview query (e.g. 10 latest rows with that field) to see a sample, then write the real query using the observed shape.
5. **Write a single `explore`** using what you read in step 2.
6. **Validate** with [](../validate-aql/) and fix any errors.
7. **Run** it with [](../run-aql/) and answer from the result.

## Core principles
* Think **metric-centric**, not table-centric (SQL). Do **NOT** write joins — AQL joins automatically through relationships.
* Prefer **existing** dimensions/measures/metrics; don't redeclare them. Never invent models, fields, functions, or arguments; use documented ones with the correct argument order.
* Reuse AQL from earlier in the conversation — even a partially relevant query may hold measures, metrics, or filters that apply to the new one.
* Give human-readable **snake_case** names to explore dimensions/measures, always add `sorts`, and **narrow the result** to exactly what's asked (if the user asks for a total, return only the total — not raw rows).
* Prefer native time functions (`running_total`, `relative_period`, `period_to_date`, …) for period comparisons.
* AQL has no visual features ("highlight", "% format", "color", "column chart") — those belong to the visualization. Leave them out of the query and handle them with [](../visualize-data/).
* If a feature seems missing or you hit an error, assume it's a knowledge gap (wrong function/args) — check the [](../aql/) references — not an AQL bug.

## Presenting the result
* Prefer a visualization ([](../visualize-data/)) over a plain table whenever it reads better — e.g. always for cohort retention.
* `execute_aql` shows the AQL and its result to the user directly. Don't repeat them; summarize the notable numbers (or a short insight) instead.
* If the AQL comes from a past conversation, say so in your answer.

## Delegating to Holistics AI
`generate_aql` spawns a Holistics AQL sub-agent that writes the query from a natural-language request. When using it:
* Provide all relevant data context (sample data, past errors, earlier AQL) in the `query`.
* Quote filter values only if you know they're exact (e.g. "Vietnam", `England`); otherwise leave them unquoted, since a quoted wrong value filters wrongly.
* For opaque fields (structs, JSON, "settings"), preview the data first and pass the observed shape — e.g. ``Example of `users.settings`: `{"enable_spell_check": true, "theme": 3}` `` — rather than only a JSON path.
* Omit visual requirements from the `query`; pass them to the visualization step instead.
* Run the result with [](../run-aql/) as usual.

## Related skills
* [](../aql/) — AQL knowledge and reference docs.
* [](../lookup-values/) — verify exact filter values before filtering.
* [](../validate-aql/) — validate a query or expression before running it.
* [](../run-aql/) — run a validated query and get its result.
* [](../visualize-data/) — show the result as a chart or formatted table.
