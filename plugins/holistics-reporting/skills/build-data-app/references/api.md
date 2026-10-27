# Anfra SDK: author API

Everything hangs off the global `Anfra`. It is ready before your first `<script>` runs: no
import, no setup, no await.

## Environment

- `Anfra.datasets`: `Record<key, descriptor>`, the datasets this reader can use, keyed by what a
  query's `dataset:` takes. A descriptor is
  `{ name, label, data_models: [{ name, label, fields: [{ name, label, type, is_custom_measure }] }], metrics: [{ name, label, type }] }`:
  `is_custom_measure` marks a model measure.
- `Anfra.user`: `{ id, name, email, role, timezone, permissions: { canViewGeneratedSql, canExportData } }`.
  The permissions are rendering hints only: the backend re-checks every query as this reader.
- `Anfra.plugins`: the plugins the host installed. See [Plugins](#plugins); never call one beyond `core`.

## Plugins

**`core` is always there.** It runs the queries and a filter's suggestions: everything below
(`createApp`, queries, controls, cross-filtering, structure) works through it. Never check for it.

The only other plugin Holistics installs is `inspect`, which adds nothing for the app: the editor's
Inspect panel reads the app's [structure](#structure) through it.

Nothing else is available: no `query.export`, no `Anfra.render`, no `Anfra.lineage`. If the user
asks for a download, an image or a PDF of the app, tell them the Data App can't offer one yet, and
don't build one from `query.result.rows` either.

## Field references

How you name a field **to the SDK** (in `createFilter` and `mapControl`):
`model.field` for a model field, a bare `name` for a dataset-level metric. Names come from
`Anfra.datasets`, never from labels. A filter's `field` is checked at once (a `ValidationError`
with a "did you mean"); a `mapControl` field is not checked until the query runs, so a typo there
arrives as a `QueryError`.

## App

```js
const app = Anfra.createApp({ title: 'Sales', timezone: 'Asia/Singapore' }); // both optional
```

Omit `timezone` to use the workspace's reporting timezone; set it to an IANA zone to evaluate relative dates and
date truncation in that zone. An HTML file may create several apps; one
is almost always right.

| Member | Does |
| --- | --- |
| `app.createQuery(name, { dataset, aql, pageSize? })` | Declares a query. Without `pageSize` it is not paged and returns every row. With one (a whole number of at least 1; anything else throws) it returns a page at a time: page further with `fetchMore()`. |
| `app.createFilter(name, decl)` | Declares a filter. See [Filter](#filter). |
| `app.createDateDrill(name, { default?, label? })` | Declares a date grain switch. See [Date drill](#date-drill). |
| `app.mapControl(control, query, { field, aggregation? })` | The control conditions `field` of `query`. |
| `app.mapCrossFilter(fromQuery, toQuery)` | Rows selected in `fromQuery` filter `toQuery`. |
| `await app.execute()` | Runs every query whose inputs changed. Resolves `{ succeeded, failed }`, never rejects. |
| `await app.refresh()` | Re-runs every query, whether or not its inputs changed. |
| `app.subscribe(fn)` | Calls `fn` on any change in the app or its entities. Returns an unsubscribe. |
| `app.hasChanges` | A control or the selection changed since the last execute: use for an "Apply" button. |
| `app.selection` / `app.clearSelection()` | The current cross-filter selection. |
| `app.abort()` | Cancels in-flight queries. |

Names are unique per app across queries and controls.

### Adding queries later

Entities and mappings can be declared at any time, including after `execute()`: the next
`execute()` runs whatever is new. A query's AQL is fixed once declared, and nothing can be removed,
so an app whose query changes with the reader's choices (a query builder, a pivot picker) declares
a **new query** for each new AQL:

- Give each one a unique name (`run1`, `run2`, …) and render only the latest.
- `query.abort()` the previous one if it may still be running.
- Earlier queries keep their last result and stay idle, since `execute()` only re-runs a query
  whose own inputs changed. A mapping can't be removed, though, so a control mapped onto an old
  query keeps re-running it. Give each new query its own controls, or start a fresh
  `Anfra.createApp()` and `abort()` the old app.

### Mappings are explicit

Nothing is wired for you. A filter on `users.region` affects no query until you
`mapControl(region, query, { field: 'users.region' })` for each query it should reach. The mapped
field need not be selected by the query. With `aggregation` (`'sum'`, `'avg'`, `'count'`,
`'count distinct'`, `'min'`, `'max'`, …) the condition applies to the aggregate, and the server puts
it in the query's `having`: a "revenue over 1000" filter is
`mapControl(minRevenue, byRegion, { field: 'orders.amount', aggregation: 'sum' })`. A mapping onto
a bare dataset metric is an aggregate condition too.

## Query

| Member | Does |
| --- | --- |
| `query.state` | `'idle' \| 'executing' \| 'success' \| 'error'` |
| `query.result` | `{ columns, rows, meta: { numRows, page?, pageSize? }, debug? }` (`page` and `pageSize` only for a paged query), or `undefined` before success. Kept while re-executing, so you can render stale data under a spinner. |
| `query.error` | The error when `state === 'error'`. |
| `query.setSort([{ field, direction }])` | Sorts by a result column `name`. `[]` restores the AQL's own sort. Re-run with `execute()`. |
| `query.hasMore` / `await query.fetchMore()` | Appends the next page. Unlike `execute`, `fetchMore` rejects on failure. A query with no `pageSize` has no more pages: `fetchMore` rejects with a `ValidationError`. |
| `query.select(rows, { fields? })` | Sets the app's selection from rows of this query. `fields` (result column aliases) limits which columns become conditions. See [Cross-filtering](#cross-filtering). |
| `query.selectedRows` | This query's rows that are currently selected, for highlighting. |
| `query.abort()` | Cancels this query's in-flight request. |
| `query.subscribe(fn)` | Change listener for just this query. |
| `query.locate()` | Scrolls to the elements marked `data-anfra-query` with this query's name and shows them for a moment. See [Structure](#structure). |

### Result shape

```js
query.result.columns // [{ name, fieldName, modelId?, label, adhoc, isMeasure, aggregation?, semantic_type, arrow_type, db_type }]
query.result.rows    // [{ month: '2026-01-01', total: '1234.5' }, ...]
```

- Row keys are the **aliases your AQL declared** (`month`, `total`), matching `column.name`.
  `column.fieldName` is the underlying field, which you only need for debugging.
- Values are raw, never formatted. Format numbers and dates yourself (`Intl.NumberFormat`,
  `toLocaleDateString`). Log `rows[0]` on first success to confirm the value types rather than
  guessing.
- **Every number arrives as a string**, with every digit: `"9007199254740993"`, `"97537.24"`, and
  a float's `"NaN"`, `"Infinity"` or `"-Infinity"`. Dates arrive as ISO strings
  (`"2025-06-01T00:00:00Z"`), `null` as `null`.
- **Decide by `column.semantic_type`, never by `typeof`**: `number`, `text`, `date`, `datetime`,
  `truefalse`, `json`, `bit` (a true or false stored as a bit: `true`/`false`, or `"1"`/`"0"`), or
  `unknown` (a type AML gives no meaning yet).
- **Display** a number with `Intl.NumberFormat`, which formats the string as it is:
  `money.format(row.revenue)`.
- **Compute, chart or sort** with `Number(v)`. Never do arithmetic or `<` on the strings: `"1" + 2`
  is `"12"`, and `"10" < "9"` is true. Check for `null` first, since `Number(null)` is `0`.
  `Number(v)` keeps every digit of a `floating_point` column (`column.arrow_type.type`). An `int`
  with `bit_width` 64, or a `decimal`, can lose digits past about 15 significant digits: keep an
  ID as its string, and compare IDs with `===` on the strings.
- **Exact arithmetic**: prefer computing it in the query, as an aggregate or a metric (`sum`, `avg`,
  a ratio), which the database computes with every digit. Only when it must happen in the
  browser, give the string to a decimal library instead of `Number(v)` (`new Decimal(row.revenue)`
  with decimal.js or big.js), or to `BigInt` for whole numbers (`BigInt(row.id)`; its division
  drops the remainder).
- `column.label` is a display label; prefer it for axis and header text.
- `result.debug` has `executedAt`, `executedSql`, `fromCache`, and for an AQL query `executedAql`: your AQL
  with the reader's filters, sorts and date drills applied — the first thing to log when a
  control seems to do nothing.

## Structure

A definition can mark its parts in its HTML, so the editor's Inspect panel shows them as a
tree (hover to see one on the page, click to scroll to it, Pick to go from the page to the tree),
and so an author can hand an agent a handle for one. Mark every part the app renders; it costs one
attribute each.

```html
<main data-anfra-container="page" data-anfra-label="Overview">
  <div data-anfra-container="controls" data-anfra-label="Controls">
    <label data-anfra-block="region-picker" data-anfra-control="region">…</label>   <!-- a block drawn by a control -->
  </div>
  <div data-anfra-container="kpis">
    <div data-anfra-block="revenue" data-anfra-query="totals">…</div>   <!-- a block drawn by a query -->
    <div data-anfra-block="orders"  data-anfra-query="totals">…</div>   <!-- the same query, another block -->
  </div>
  <section data-anfra-block="trend" data-anfra-label="Revenue over time">
    <div id="trend-chart" data-anfra-query="trend"></div>               <!-- the chart the query draws -->
    <select data-anfra-control="grain"></select>                        <!-- and its control, in the same block -->
  </section>
</main>
```

| Attribute | On | Means |
| --- | --- | --- |
| `data-anfra-container="<id>"` | any element | A container: holds anything. |
| `data-anfra-block="<id>"` | any element | A block: the smallest thing a reader sees as one. Holds no container or block. |
| `data-anfra-label="<text>"` | a container or block | Its display name in the tree. Optional. |
| `data-anfra-query="<name>"` | any element | This element is drawn by that query. Several names space-separated. On a block's own element it means the block is drawn by it. |
| `data-anfra-control="<name>"` | any element | The same, for a filter or date drill. A control lives in a block like a query does: its own block when it stands alone, or the block of the chart it belongs to. |

- Names are the ones given to `createQuery`, `createFilter` and `createDateDrill`. In a file that
  creates several apps, write `app/name` with the app's index (`1/trend`); a bare name is app 0.
- Ids are required and unique per kind in the document.
- Every query and control marker sits in a block, or on a block's own element. A control that
  stands alone (a filter in a toolbar) gets a block of its own; a control that belongs to one chart
  (a grain switch in a chart's header) goes in that chart's block.
- The markup is optional, partial, and read only while the Inspect panel is open. A mistake (an
  unknown name, a duplicate id, a block inside a block) is shown on the node in the tree, never
  thrown. Elements added later (a table drawn on the first result) appear once they exist.
- `query.locate()` and `control.locate()` scroll to the elements marked with that entity and show
  them for a moment, for a "find on page" button of the app's own. They return `false` when
  nothing is marked yet, and never throw.

**Handles.** A user who has picked a node in the panel may paste its handle into a request:
`[Revenue over time](data-anfra-block="trend")`, or just `data-anfra-block="trend"` when the
node has no label. The part in parentheses is the attribute as written in the file: search the
definition for it to find the element the user means, then change that element and what draws it.

## Filter

```js
// Field-backed: options come from the field, filtered by the reader's permissions.
const region = app.createFilter('region', { dataset: 'sales', field: 'users.region', label: 'Region' });
await region.loadOptions();        // or loadOptions('ap') to search; then read region.options

// Manual: you supply the type, plus a fixed list or nothing (free input).
const tier = app.createFilter('tier', { type: 'string', options: ['Gold', 'Silver'] });
```

Always pass `dataset:` alongside `field:`. It is only optional when the reader can see exactly one
dataset, which is rare.

A filter, like a date drill, has `locate()` too: see [Structure](#structure).

Set a filter's value with a **condition**, then call `execute()`:

```js
region.setCondition({ operator: 'is', values: ['APAC', 'EMEA'] });  // IN list
region.setCondition({ operator: 'is', values: [] });                // no filter
region.reset();                                                     // back to the declared default
```

Useful operators by type (the full list is in the SDK's `Operator` type):

- any: `is`, `is_not`, `is_null`, `not_null`
- string: `contains`, `does_not_contain`, `starts_with`, `ends_with` (all case-insensitive)
- number: `greater_than`, `less_than`, `between` (`values: [lo, hi]`). A number filter's values are strings, as results give them: `values: ['100']`. A JS number throws, since it may already have lost digits.
- date: `between` (`['2026-01-01', '2026-03-31']`), `before`, `after`, `last`/`next`
  (`values: [7], modifier: 'day'`), `matches` (`['last 3 months']`, `['year to date']`: any
  phrase from [Natural Time Expression](https://docs.holistics.io/docs/datetimes/relative-dates.md),
  resolved by the server in the app's timezone)
- boolean: `is_true`, `is_false`

`matches_user_attribute` and the `transform_pop_*` operators are not supported; a query
they reach fails with a `QueryError`.

A condition with no values (or `operator: 'none'`) sends nothing: the query runs unfiltered. Give a
filter a starting value with `default: { operator, values }`.

## Date drill

```js
const grain = app.createDateDrill('grain', { default: 'month' });
app.mapControl(grain, trend, { field: 'orders.created_at' });
grain.setGrain('week'); // 'year' | 'quarter' | 'month' | 'week' | 'day' | 'hour' | 'minute'
```

The server finds every dimension of the query built directly on that exact field and redraws it
at the grain, so:

- Map to the **field reference** (`orders.created_at`), never the dimension's alias. A field no
  dimension is built on fails the query with a `QueryError`.
- The dimension must be **aliased**, and can be the raw field (`period: orders.created_at`) or
  already truncated (`period: date_trunc(orders.created_at, "month")` or
  `period: orders.created_at | month()`); the drill overrides any of them. A computed dimension
  that merely uses the field is left alone.
- The row key stays the alias whatever the grain, so give it a grain-neutral name like `period`.

## Cross-filtering

```js
app.mapCrossFilter(byRegion, trend);                    // one direction
app.mapCrossFilter(trend, byRegion);                    // add the other if both should drive

chart.on('click', (p) => {
  const row = byRegion.result.rows[p.dataIndex];
  const selected = byRegion.selectedRows;
  byRegion.select(selected.includes(row)
    ? selected.filter((picked) => picked !== row)
    : [...selected, row]);
  app.execute();
});
```

- `query.select(rows)` replaces the selection with the full array. Pass multiple rows together;
  the click handler above toggles each row in or out. `query.select([])` clears the selection.
- Conditions are **ANDed within each row, ORed between rows**: `(A and B) or (C and D)`.
  Selecting `(APAC, Aug 2025)` and `(EMEA, Oct 2025)` preserves those pairs rather than matching
  every combination of the two regions and months. Selecting Aug 2025 and Oct 2025 on a monthly
  chart includes those two months, leaving September out. The SDK builds the conditions from the
  selected rows and the applied date grain.
- Pass **row objects from `query.result.rows`**, never rebuilt objects: the SDK reads the dimension
  values off them.
- Only dimension columns become conditions; measures and query-local expressions are skipped. A
  dropped expression column sets `app.selection.lossy` and logs a warning.
- `query.select(rows, { fields: ['region'] })` narrows the conditions to those result column
  aliases (dimensions only). Naming a measure, a query-local expression or an alias missing from
  the last result throws a `ValidationError`.
- One selection per app: selecting in another query replaces it. The source query is never
  filtered by its own selection, so its `result` is the same object after a click. Use
  `query.selectedRows` to dim the unselected marks, and restyle the chart in place: a render that
  rebuilds the series on every change (ECharts' `replaceMerge`, or `clear()` then `setOption`)
  replays the chart's entry animation each time the reader clicks. Rebuild only when `result`
  changed.
- Both queries must use the same dataset. No self-edges.
- Clear with `app.clearSelection(); app.execute();`.

## Errors

| Class | When | What to do |
| --- | --- | --- |
| `ValidationError` | Thrown synchronously while declaring: unknown dataset, unknown filter field, duplicate name, invalid mapping, disabled capability. | Fix the declaring line it names. It surfaces as an uncaught error in the console. |
| `QueryError` | Stored on `query.error`: the server rejected the AQL, a mapped field or operator, or the query failed. | Read the message, which names the AQL problem or the bad entry (`filters[0].field`); fix the AQL or the mapping. |
| `PermissionError` | Stored on `query.error`: this reader can't see the data. | Render "no access", not a failure. |
| `TransportError` | Network or session problem. | Show a retry. |

Every error has `entity`, the query or control name it concerns. Check the class with `err.name`
(`'PermissionError'`), since the classes themselves aren't exposed as globals.
