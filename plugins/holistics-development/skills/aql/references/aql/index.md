<Hero
  title="AQL Reference"
  subtitle="Signatures, grammar, and per-function details for the Analytics Query Language." />

This is the reference for AQL: the signatures, the grammar, the function-by-function details. Use it to look something up.

For *concepts* (what AQL is for, how metrics work, how to think about Level of Detail, time comparisons, the order of operations), head to [AQL & Metrics](/as-code/aql/) in the Documentation section.

## How this section is organized

AQL has a small grammar and a large function library. These pages map to that split: a handful of grammar pages, then the function library grouped by category.

<CardGrid cols={3}>
  <Card title="AQL expressions" href="/reference/aql/expression" cta="Read the reference">
    The three kinds of expression you can write: table, metric, and explore.
  </Card>
  <Card title="Operators" href="/reference/aql/operator" cta="See the operators">
    The full set: `==`, `+`, `between`, `like`, `is null`, and the rest.
  </Card>
  <Card title="Pipe" href="/reference/aql/operator#pipe" cta="How chaining works">
    The `|` that chains functions together by passing the left side into the right.
  </Card>
  <Card title="AQL types" href="/reference/aql/type-index" cta="Browse the types">
    The type system: scalars, tables, dimensions, fields, and measures.
  </Card>
  <Card title="Functions" href="/reference/aql/function" cta="Browse by category">
    The function library, grouped by category from aggregators to window functions.
  </Card>
</CardGrid>

## Quick lookup

If you already know what you're looking for, these flat tables are the fastest way in.

<CardGrid cols={2}>
  <Card title="Functions cheatsheet" href="/reference/aql/functions" cta="Open the cheatsheet">
    Every function in one scannable table, with full docs a click away.
  </Card>
  <Card title="Operators cheatsheet" href="/reference/aql/operators" cta="Open the cheatsheet">
    Every operator with a syntax example for each.
  </Card>
</CardGrid>

## See also

- [AQL & Metrics](/as-code/aql/): conceptual guides and learning material
- [AML Reference](/reference/aml/): the modeling DSL that AQL queries against
