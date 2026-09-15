# Campaign selection, run dates, and network average

Use this synthetic scenario to reason about dependent filters. It is an illustrative design exercise, not a claim about a customer's actual schema or metric contract.

## Establish the intended computation

Suppose a dashboard chooses a campaign, derives the dates when that campaign ran, then calculates a network benchmark on those dates.

Trace the dependency in LookML and generated SQL:

1. Campaign selection filters the campaign/run relationship.
2. That relationship produces a set of run dates.
3. Run dates restrict network observations.
4. The network metric aggregates the restricted observations.

## Owner decisions

Resolve these questions from LookML, generated SQL, and report specs first. Ask one remaining blocking question at a time, with evidence, a recommendation, and consequences:

- Are run dates actual activity dates or every date between minimum and maximum?
- For multiple campaigns, is the date set a union, intersection, or separate result per campaign?
- Does the benchmark include all network members, only participating members, or a permission-restricted subset?
- Does campaign selection affect the benchmark only through dates, or also through network membership?
- Is the average weighted by observations, exposure, member, or day? Are missing days zero or absent?
- What do no selection, unknown campaigns, campaigns with no runs, and overlapping dates mean?
- Can permitted users see the benchmark without learning restricted campaign or network details?

For example, when code and requirements conflict: “LookML uses actual run dates, but the report spec says the full campaign period. Including gap days changes the benchmark. I recommend preserving Looker behavior for this migration. Which definition should the migrated report use?” When evidence agrees, preserve established behavior without asking.

## Candidate Holistics design

One candidate is a Query Model with a typed campaign parameter:

1. Restrict campaign/run data with the parameter.
2. Derive distinct eligible dates.
3. Restrict network facts to those dates.

A modeled bridge with reusable AQL metrics is another candidate. Use it only if relationships and filters preserve the same scope.

The date set must not duplicate network observations when multiple campaigns share dates. A semijoin or deduplicated date relation is a candidate; verify exact implementation against the warehouse and target tooling.

Wire the dashboard FilterBlock explicitly to the campaign input. Apply the campaign predicate only to the branch authorized by the business contract. An ordinary campaign filter on the final network rows may change the benchmark population or fail when campaign is absent from the final model.

Do not assume raw SQL inherits row-level or column-level permissions (RLP/CLP) from models that reference the same tables. Verify the current permission behavior, then configure the Query Model's policy or a path with proven permission enforcement.

Inspect generated SQL for both date derivation and network aggregation. A final-result predicate alone may leave sensitive intermediate computations exposed.

Prove enforcement in restricted-user sessions. Test campaign suggestions and direct submission of parameter values absent from the dropdown.

Clearing a campaign filter to compute an all-network benchmark must never remove security predicates. Check parameter-dependent persistence/cache behavior and cross-user cache isolation before enabling it.

## A discriminating fixture

Use disposable test data with the owner-approved definition: union of actual run dates, all authorized network observations on those dates, observation-weighted arithmetic mean.

- Campaign A runs on dates D1 and D3, not D2.
- Campaign B runs on D3 and D4.
- Network observations: D1 has values 10 and 30; D2 has 1,000; D3 has 90; D4 has 60.

Expected values, derived independently of the target implementation:

- selecting A gives (10 + 30 + 90) / 3 = 43.333…;
- selecting B gives (90 + 60) / 2 = 75;
- selecting A and B gives (10 + 30 + 90 + 60) / 4 = 47.5 because D3 is included once;
- intersecting A and B dates instead of taking their union gives 90, which is wrong under this contract;
- averaging daily means for A instead gives (20 + 90) / 2 = 55, also wrong;
- replacing A's actual dates with a min/max range includes D2 and gives 282.5; for A+B it gives 238, both wrong;
- joining without deduplicating shared dates for A+B gives (10 + 30 + 90 + 90 + 60) / 5 = 56, also wrong.

Add cases for unknown/empty campaigns, null dates, unequal member counts, and date-boundary timezones.

For a user allowed only D1 observations:

- selecting A must yield 20;
- selecting B must yield no authorized observations, not 75 or an all-network fallback;
- check the agreed empty-result display separately: no rows or a null aggregate, without a numeric benchmark.

A missing/blank security attribute must fail closed, never expose all rows. Test campaign visibility separately. Denied campaign names and dates must not be inferable from suggestions or direct parameter submissions.

Derive the expected outcome for no selection from the owner's answer rather than inventing a default.

Pass requires matching both the selected date set and final metric. A correct final number on one symmetric fixture can conceal the wrong filter placement.
