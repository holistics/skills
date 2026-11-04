---
name: build-data-app
label: Build Data App
description: |-
  Build a Holistics Data App, one self-contained HTML page that queries the user's datasets through the `Anfra` SDK and renders them with its own HTML, CSS and JS, and save it with `create_data_app`.

  Use when the user asks for a Data App, or a custom page, report or interactive analysis over their datasets saved as an app.

  Do NOT trigger for a one-off chart or data question, or for a canvas dashboard.
---

# Building a Data App

A **Data App** is one self-contained HTML file stored in Holistics and edited in its Data App editor.
It runs in a sandboxed frame where the SDK is already on the global `Anfra`. The SDK supplies
data and state; every pixel is yours. You never run the app yourself: the user runs it and reports
back, so their console and the editor's Inspect panel are your only debuggers.

References, in this file, read when a step needs them:

- [SDK reference](#anfra-sdk-author-api): every SDK call, the result shape, page structure and errors. **Read it before
  writing any code; do not invent APIs.** Only the core SDK is available: no export, render or
  lineage.
- `generate_aql` drafts the query bodies; `execute_aql` runs each one before you save.
- [Example](#example): a complete app in the default Holistics look. Start the file from its
  skeleton.

## 1. Collect the datasets and the idea

You need the **datasets** the app may use (their fields and metrics) and a **description** of the
app.

1. **No `create_data_app` tool** (a non-interactive run, or Data Apps not enabled): tell the user
   you can't create Data Apps here, and stop.
2. **No description:** ask what the app should show and who it's for, in one short question. Don't
   suggest app ideas unless the user asks for them.
3. With the description in hand, call `list_datasets` and shortlist the datasets that fit. Skip
   ones tagged `Archived` or `Deprecated` or similar. You show the shortlist in step 2.
4. Call `fetch_dataset` for each. Its `relationships` show which models join, and its
   descriptions carry the modeler's caveats on grain, fan-out and which date to use: follow
   them.

For every dataset:

- A dataset's key (`uname` from `fetch_dataset`) is what `dataset:` takes.
- A field is `model.field`, with the model name exactly as `fetch_dataset` gives it
  (`ecommerce_orders.created_at`, not `orders.created_at`); a dataset metric is its bare name.
  A filter's or mapping's `field` is the same `model.field` the query uses.
- If a number the app needs has no field or metric, declare it as a query-local metric in the AQL.
  If AQL can't express it, tell the user it needs adding to the dataset; never compute it in
  JavaScript.

Done when you hold a description and the fields and metrics of every dataset the app may use.

## 2. Agree on the design

1. **Restate the request** as one result the user can check ("revenue for the last full week
   against the week before, with a country picker"). When the data cannot answer it, say so and
   offer the nearest thing it can.
2. **Ask only what changes the numbers**: what a business word means, which date counts, what to
   exclude. One question at a time, each with your recommended answer; skip what the description
   already settles.
3. **Ask which look they want**, unless they said: the **default style** (recommended),
   **something creative** (you choose palette and layout), or **their own design** (a brand,
   colors or a reference). See [Look and feel](#look-and-feel).
4. **Write the declaration list**, one line per item:
   - **Datasets:** the shortlist from step 1.
   - **Entities:** every `createQuery` (dataset, dimensions, measures), `createFilter`,
     `createDateDrill`, `mapControl` and `mapCrossFilter`, using only names that appear verbatim
     in the environment or are declared query-local in the AQL.
   - **Rendering:** chart or table per query (default ECharts 6 from jsDelivr, as in the example).
   - **Cross-filtering:** which clicks filter which queries (same dataset only), and whether they
     replace the selection or toggle rows (see [Cross-filtering](#cross-filtering)).
5. **Show the list and get a yes** before writing the file.

## Look and feel

An app must look finished without the user asking: no native controls, default buttons or unstyled
text. In every look (default, creative or their own design):

- A filter is a styled dropdown with search, multi-select for several values, never
  `<select multiple>`. For dates, two styled `<input type="date">` and preset buttons, as in the
  example.
- Give ECharts hex colors: it cannot parse `oklch`.

Then by look:

- **Default style (Holistics):** start from the example, which maps Holistics' in-app tokens onto
  [Basecoat UI](https://basecoatui.com), with pinned CDN CSS and JS. Use its tokens as CSS
  variables, Inter, its text sizes (24px page title, 14px card titles and body, 12px captions),
  32px controls, one Blue 600 primary action and the chart palette (Blue 600 first). Green, purple
  and amber belong in charts and status, never on actions.
  - Filters are Basecoat comboboxes (`aria-multiselectable="true"` for several values).
  - Basecoat `.card` is a flex column that clips overflow. On a filter bar card set
    `flex-direction: row; align-items: flex-end; overflow: visible` (as `.card.filters` in the
    example), or the controls drift right and dropdowns get cut off.
- **Creative:** your own palette, type and layout, in Basecoat or your own CSS, keeping readable
  contrast, tabular numerals, light and dark (`prefers-color-scheme`), and styled loading, empty
  and error states.
- **Their own design:** follow it. Take only the SDK wiring and the sandbox rules from the example,
  not its look.

## 3. Write the file

Write the app as one whole HTML document, handed over as step 4 says. Follow the example's
skeleton: declare everything, `subscribe` a render function, `execute()`, then wire controls and
clicks to set state and `execute()` again. Keep the look (styles, markup, chart theme) apart from
the SDK wiring.

**Fit it in one reply.** You write the whole file inside one `create_data_app` call, and one reply
holds at most 8,192 output tokens: a longer file is cut off and never saved. Aim for about 15KB of
HTML:

- Write no comments: leave out the example's and add none of your own.
- Keep only the CSS rules, tokens and classes the page uses.
- Build at most 4 queries and 4 charts or tables in the first version, then offer to add more. When
  the agreed list holds more, build the first 4 and name the rest in that offer.
- Draw every chart and table through one shared render helper rather than repeating the setup per
  chart.
- Add a control (date presets, grain switch, cross-filter) only when the user asked for it or the
  agreed list names it.

**Queries.** Draft each `aql` with `generate_aql` when you need help with the syntax, then run each
query once with `execute_aql` on its dataset and fix any error before saving. The SDK applies the reader's state (filters,
selection, sorts, date drills, page) to the query's `explore { }` before it runs, so a pipe-style
query fails as soon as a reader touches a control, sort or date drill mapped to it. Nothing a reader
changes goes in the AQL text: static conditions go in `filters`; a reader's choice is a control
(`createFilter` + `mapControl`). Write flat table queries, not pivot queries (`rows { }` /
`columns { }`): pivot the rows in the app when it needs a pivot. Alias every dimension and measure
(`region: users.region`, `revenue: orders.total_revenue`): sorts, date drills, cross-filters and
row keys all go by the alias.

**The sandbox** allows scripts only, has an opaque origin and a content policy:

- Data comes only from the SDK. `fetch`, XHR, WebSocket and `sendBeacon` are blocked except to the
  CDNs below; never call any service from the app.
- Libraries, styles and fonts load only from cdn.jsdelivr.net, cdnjs.cloudflare.com and Google
  Fonts, by `https://` URL with a pinned version. Everything else is blocked, esm.sh and unpkg.com
  included: load npm packages from jsDelivr (`/npm/<pkg>@<version>/<file>`), and ES modules from
  its `+esm` build. Images may come from any `https://` server.
- Every CDN `<script src>` and stylesheet `<link>` carries `integrity="sha384-…"
  crossorigin="anonymous"`, as in the example. You can't look a hash up and a wrong hash blocks
  the file, so use only the libraries, versions and hashes in the example. Load fonts from
  `@fontsource` on jsDelivr, as the example does: Google Fonts' CSS differs per browser, so it
  can't be hashed.
- The app is its one HTML file: no relative `src` or `href`. Inline your scripts and styles, and
  images as SVG or a `data:` URI.
- `localStorage`, `sessionStorage` and cookies throw: keep state in variables, and follow
  `prefers-color-scheme` rather than Basecoat's theme switcher, which stores the mode.
- Forms, popups, navigation, `<iframe>` and `<base>` are blocked: use buttons and `change`
  listeners, never `<form>`.

**Structure.** Mark the page as [Structure](#structure) shows: `data-anfra-container`
and `data-anfra-block` (with a `data-anfra-label`) on its parts, and `data-anfra-query` or
`data-anfra-control` on the element each query and control draws into. Every query and control
sits in a block; a chart's own control goes in the chart's block. The Inspect panel shows this tree
and gives the user a handle for each part to hand back to you.

**Rendering.**

- Render each query's four states: `executing`, `success`, `error` (show `error.message`, and a
  distinct "you don't have access" for `PermissionError`), and success with no rows ("No sales this
  week", never a bare zero).
- On a selection change, restyle the marks already drawn (dim the unselected ones) rather than
  rebuild the chart, which would replay its entry animation on every click. With ECharts, merge a
  selection with a plain `setOption(option)` and keep `replaceMerge` for a new result.
- Put on the page the definitions, dates and rounding a reader needs to trust a number.

Record **generation metadata** in `<head>`, as the first child after `<meta charset>`:

```html
<script type="application/json" id="data-app-metadata">
{
  "prompt": "a sales overview with revenue by region and a monthly trend",
  "model": null,
  "effort": null,
  "createdAt": null,
  "updatedAt": null
}
</script>
```

- `prompt`: the user's description, verbatim, never summarised or corrected: the invocation text
  without any pasted snapshot, else their first message describing the app. It is fixed for the life of the file.
- `model`: the model name or identifier explicitly supplied by the runtime or session context for
  the latest revision. Use `null` when unavailable; do not infer it from the agent or product name.
- `effort`: the configured reasoning effort for the latest revision, when explicitly available
  (for example, `"high"`). Otherwise use `null`; do not estimate it from task complexity.
- `createdAt`: the first generation's UTC timestamp in ISO 8601 format, read from an available
  clock (for example, `"2026-09-24T14:30:00Z"`). Preserve it on later revisions.
- `updatedAt`: the latest revision's UTC timestamp, read when producing the file. On first
  generation, set it equal to `createdAt`. Use `null` for unavailable timestamps rather than
  inventing a time or using the time the reader opens the app.

Serialize the metadata as JSON, escaping every `<` as the literal JSON escape `<` so prompt
text cannot close the script tag. Keep the block static, with no runtime script to populate it.
When editing an older file, add missing fields using these rules; an unknown original creation
time stays `null`.

Done when the file fits in one reply (about 15KB, no comments, only the CSS it uses, at most 4
queries and 4 charts or tables, one shared render helper, no unrequested controls), holds every
entity from the agreed list within that limit, every part is marked, each query
renders all four states and ran once through `execute_aql` without error, every CDN asset carries its hash, the example's error banner script is kept,
and the metadata block has all five fields with known values or explicit `null`s.

## 4. Hand over and iterate

You can't run the app against the user's data, so check every name against the environment before
handing over.

**Save with `create_data_app`**: `title`, the whole document as `code`, and a one-line
`description`; leave out `category_id`, since the user picks the folder. The chat shows the user a
folder picker; picking a folder is their approval to save the design agreed in step 2, and the app
is saved there in the same call.

If `create_data_app` fails, nothing was saved:

- **Server error or timeout:** retry `create_data_app` once with the same arguments. The folder
  picker shows again.
- **Anything else** (the user cancelled or didn't answer, no permission in that folder or for Data
  Apps at all, the folder no longer exists, or no permission to edit the app you are replacing), or
  the retry fails too: tell the user in one sentence, following the error's message, and offer to
  help another way. Call `create_data_app` again only when the user asks.

On success, hand over the app exactly as the tool's `note` says.

Tell them, in their terms, what the page shows and how to use each control, the assumptions you
made, and that you could not run it yourself. Ask them to open it (or use the preview in the
chat), try every control and click, and check one headline number against one they trust. If
anything is off, ask for:

- what they see, against what they expected;
- the console panel contents;
- for a query that errored or looks wrong, its entry in the editor's Inspect panel (state,
  executed AQL, error), and any problems the panel shows on the structure tree.

A page that shows its static markup but nothing the script fills in (placeholder text, no rows,
half the styles) means the script never ran. The error banner from the example names the line
where the parser noticed, usually at or just after the problem.

Read their report against [Errors](#errors): a `ValidationError` names a declaring
line; a `QueryError` carries the server's message about the AQL, or names the bad entry
(`filters[0].field`). Compare a misbehaving query's executed AQL with what you meant. A query
marked "Not drawn yet" has no element marked with it. When the user names a part by its handle
(`data-anfra-block="trend"`), search the file for that attribute: it is the element they mean.

Change the smallest thing that explains the problem, and restate a change first if it alters what a
number means. Save the whole updated file with `create_data_app` and `overwrite_app_id` set to the
`id` your own `create_data_app` call returned earlier in this chat; no folder picker shows. Overwrite
only that app, even when the user names another one they can edit: tell them you can only change
apps you created in this chat. Without `overwrite_app_id` each call makes a new app. Tell the user
that overwriting replaces any edits made in the editor since. Preserve `prompt` and `createdAt`,
refresh `model`, `effort` and `updatedAt`, and repeat until the user says it's done.

Done when your reply hands over the app as the tool's `note` says.

---

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
  `toLocaleDateString`).
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

---

# Example

A complete app in the default Holistics look. Start the file from its skeleton.

```html
<!doctype html>
<!--
  A complete Data App: a region multi-select, a date range, a date grain switch, a bar chart that
  cross-filters a trend line. Dataset `ecommerce` and the `orders` / `users` fields are placeholders:
  replace them with names from the user's data snapshot.

  Two layers, change one without the other:
  - Design layer: the Basecoat links, the <style> block (Holistics' in-app tokens mapped onto
    Basecoat's variables), the markup classes, and chartTheme().
  - SDK wiring: everything in the last <script> that touches `app`, a query, a filter or a drill.
  This is the default Holistics look. Only replace it if the user asked for another design.
-->
<html>
<head>
  <meta charset="utf-8">
  <script type="application/json" id="data-app-metadata">
  {
    "prompt": "Sales overview: revenue by region as a bar chart that filters a revenue trend, with region and date filters and a week/month/quarter switch",
    "model": null,
    "effort": null,
    "createdAt": null,
    "updatedAt": null
  }
  </script>
  <script>
    // Error banner: shows any script error on the page, so a broken paste or a crash never leaves a
    // silent blank page. Keep it first, before every other script, so it sees their errors too.
    (() => {
      const show = (text) => {
        let banner = document.getElementById('app-error-banner');
        if (!banner) {
          banner = document.createElement('div');
          banner.id = 'app-error-banner';
          banner.setAttribute('role', 'alert');
          banner.style.cssText = 'position:fixed;inset:0 0 auto 0;z-index:2147483647;padding:8px 16px;' +
            'background:#E53E3E;color:#FFFFFF;font:13px/18px system-ui,sans-serif;white-space:pre-wrap';
          (document.body || document.documentElement).append(banner);
        }
        banner.textContent += (banner.textContent ? '\n' : '') + text;
      };
      window.addEventListener('error', (event) => {
        show(`Script error${event.lineno ? ` on line ${event.lineno}` : ''}: ${event.message}`);
      });
      window.addEventListener('unhandledrejection', (event) => {
        show(`Unhandled error: ${event.reason?.message ?? event.reason}`);
      });
    })();
  </script>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sales Overview</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fontsource-variable/inter@5.2.5/index.css"
    integrity="sha384-ZTIcl2CmY0wyM9ANOhomBco7rEUIlWztf6lGcLKCocKUrIgGCsfisuZyE+hadW8K" crossorigin="anonymous">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/basecoat-css@1.0.2/dist/basecoat.cdn.min.css"
    integrity="sha384-XWKdrxzE2X33lI8Q03C9fIbqdLWV11whVNycR2/3bMNJY73EEQOa7rmN+SeiSCor" crossorigin="anonymous">
  <script src="https://cdn.jsdelivr.net/npm/basecoat-css@1.0.2/dist/js/all.min.js"
    integrity="sha384-rD2ZCuReXV7nIneJcn1lsTn6yOv87YARLQyUsemVAxrYYHdy5hcAW8XZEQxx87Dj" crossorigin="anonymous" defer></script>
  <script src="https://cdn.jsdelivr.net/npm/echarts@6.1.0/dist/echarts.min.js"
    integrity="sha384-C2iskrW/uPW46KzOjrvJIQo4YkV8lkD+QS0CrDN18IIPIpT/g2USu8bTP3nvmIAD" crossorigin="anonymous"></script>
  <style>
    /* Holistics' in-app tokens on Basecoat's variables, light and dark. Blue 600 is the one
       primary action; ECharts cannot parse oklch, so every color is hex. */
    :root {
      --background: #F5F8FA;          /* Gray 100: the page */
      --foreground: #13151A;          /* Gray 900 */
      --card: #FFFFFF;
      --card-foreground: #13151A;
      --popover: #FFFFFF;
      --popover-foreground: #13151A;
      --primary: #1B7CE4;             /* Blue 600: the one primary action */
      --primary-foreground: #FFFFFF;
      --secondary: #D1E5FA;           /* Blue 100: a pressed segment */
      --secondary-foreground: #104A89;
      --muted: #F5F8FA;
      --muted-foreground: #4C5159;    /* Gray 700 */
      --accent: #D1E5FA;              /* Blue 100: hover, selected */
      --accent-foreground: #104A89;   /* Blue 800 */
      --destructive: #E53E3E;
      --border: #E3E7ED;              /* Gray 300 hairline */
      --input: #CBD0D7;               /* Gray 400 */
      --ring: #1B7CE4;
      --radius: 0.5rem;               /* 8px */
      /* Charts: Blue 600 first, fixed order. */
      --chart-text: #4C5159;
      --chart-grid: #EDF1F5;
      --chart-cat-1: #1B7CE4; --chart-cat-2: #259B6C; --chart-cat-3: #9250E5; --chart-cat-4: #E9AB4A;
      --chart-cat-5: #104A89; --chart-cat-6: #52C396; --chart-cat-7: #B184EC; --chart-cat-8: #8F99A3;
    }
    .dark {
      --background: #05264C;          /* Dark Blue 900 */
      --foreground: #FFFFFF;
      --card: #0A3360;
      --card-foreground: #FFFFFF;
      --popover: #0A3360;
      --popover-foreground: #FFFFFF;
      --primary: #5EA3ED;             /* Blue 400: Blue 600 is too dark on navy */
      --primary-foreground: #05264C;
      --secondary: #104A89;
      --secondary-foreground: #FFFFFF;
      --muted: #104A89;
      --muted-foreground: #D2D4D9;
      --accent: #104A89;
      --accent-foreground: #FFFFFF;
      --destructive: #E53E3E;
      --border: rgb(255 255 255 / 0.1);
      --input: rgb(255 255 255 / 0.16);
      --ring: #5EA3ED;
      --chart-text: #D2D4D9;
      --chart-grid: #104A89;
      --chart-cat-1: #5EA3ED; --chart-cat-2: #52C396; --chart-cat-3: #B184EC; --chart-cat-4: #E9AB4A;
      --chart-cat-5: #8DBEF2; --chart-cat-6: #7AD1AE; --chart-cat-7: #D0B5F4; --chart-cat-8: #B0B6BF;
    }

    /* Holistics' in-app type: 24px page title, 14px titles and body, 12px captions; one control
       height (32px); tabular numerals. */
    body {
      font: 14px/20px "Inter Variable", Inter, system-ui, sans-serif;
      font-variant-numeric: tabular-nums;
      background: var(--background); color: var(--foreground);
      margin: 0; padding: 24px; max-width: 1280px; margin-inline: auto;
    }
    h1 { font-size: 24px; line-height: 36px; font-weight: 500; margin: 0; text-wrap: balance; }
    .caption { font-size: 12px; line-height: 16px; color: var(--muted-foreground); }
    .header { margin-bottom: 16px; }
    .btn, .input { height: 32px; font-size: 14px; }
    /* The multi-select's chip box defaults to 36px: bring it to 32px, growing as chips wrap. */
    .combobox-chips { min-height: 32px; padding-block: 5px; }
    .card { border-radius: 12px; box-shadow: none; position: relative; }
    .card > header { padding-bottom: 0; }
    .card h2 { font-size: 14px; line-height: 20px; font-weight: 500; }
    /* A card header that carries the chart's own control or action, right-aligned. */
    .card > header.with-action { display: flex; align-items: center; justify-content: space-between; gap: 8px; }

    /* Filter bar: one row, wraps on narrow screens. */
    /* Basecoat's .card is a clipped column: make the bar a row and let combobox dropdowns overflow. */
    .card.filters { flex-direction: row; flex-wrap: wrap; gap: 16px; align-items: flex-end;
                    justify-content: flex-start; padding: 12px 16px; margin-bottom: 16px;
                    overflow: visible; }
    .field-group { display: flex; flex-direction: column; gap: 8px; }
    .field-group > label { font-weight: 500; }
    .date-range { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
    .date-range .input { width: 9.5rem; }
    .presets { display: flex; gap: 4px; }

    .grid { display: grid; grid-template-columns: 1fr 2fr; gap: 16px; }
    @media (max-width: 800px) { .grid { grid-template-columns: 1fr; } }
    .chart { height: 320px; }
    .status { position: absolute; inset: 56px 16px 16px; display: none; align-items: center;
              justify-content: center; background: color-mix(in oklab, var(--card) 85%, transparent); }
    .status.visible { display: flex; }
    .status > * { width: 100%; }
    .status .skeleton { height: 100%; border-radius: 8px; }
    .status .empty { text-align: center; color: var(--muted-foreground); }
  </style>
</head>
<body>
<main data-anfra-container="page" data-anfra-label="Sales overview">
  <div class="header" data-anfra-block="title" data-anfra-label="Title">
    <h1>Sales overview</h1>
    <div class="caption" id="user"></div>
  </div>

  <!-- Controls that reach several charts. A control that belongs to one chart goes in its card. -->
  <div class="card filters" data-anfra-container="controls" data-anfra-label="Controls">
    <div class="field-group" data-anfra-block="region-picker" data-anfra-label="Region" data-anfra-control="region">
      <label for="region-input">Region</label>
      <!-- Basecoat multi-select combobox: options are added once loadOptions() resolves -->
      <div id="region-combobox" class="combobox" style="width: 260px" data-auto-highlight="true">
        <input id="region-input" type="text" role="combobox" placeholder="All regions" autocomplete="off"
               autocorrect="off" spellcheck="false" aria-autocomplete="list" aria-expanded="false"
               aria-controls="region-listbox">
        <div id="region-popover" data-popover aria-hidden="true">
          <div role="listbox" id="region-listbox" aria-orientation="vertical" aria-multiselectable="true"
               data-empty="No regions found."></div>
        </div>
        <input type="hidden" name="region" value="[]">
      </div>
    </div>

    <div class="field-group" data-anfra-block="date-picker" data-anfra-label="Order date" data-anfra-control="dates">
      <label for="date-from">Order date</label>
      <div class="date-range">
        <input id="date-from" class="input" type="date" aria-label="From">
        <span class="caption">to</span>
        <input id="date-to" class="input" type="date" aria-label="To">
        <!-- Presets set the same `dates` filter, so they sit in its block. Each carries an AQL date
             phrase; an empty one means no date filter. -->
        <div class="presets" role="group" aria-label="Quick range">
          <button class="btn" data-variant="outline" type="button" data-range="last 30 days" aria-pressed="false">30d</button>
          <button class="btn" data-variant="outline" type="button" data-range="last 90 days" aria-pressed="false">90d</button>
          <button class="btn" data-variant="outline" type="button" data-range="year to date" aria-pressed="false">YTD</button>
          <button class="btn" data-variant="secondary" type="button" data-range="" aria-pressed="true">All</button>
        </div>
      </div>
    </div>
  </div>

  <div class="grid" data-anfra-container="charts" data-anfra-label="Charts">
    <section class="card" data-anfra-block="by-region" data-anfra-label="Revenue by region">
      <header class="with-action">
        <h2>Revenue by region</h2>
        <!-- Clears this chart's selection, so it lives in this chart's block. -->
        <button id="clear-selection" class="btn" data-variant="ghost" type="button">Clear selection</button>
      </header>
      <section><div id="by-region" class="chart" data-anfra-query="byRegion"></div></section>
      <div id="by-region-status" class="status"></div>
    </section>
    <section class="card" data-anfra-block="trend" data-anfra-label="Revenue over time">
      <header class="with-action">
        <h2>Revenue over time</h2>
        <!-- The grain drill only reaches `trend`, so it is this chart's control, in this chart's block. -->
        <div class="button-group" id="grain-group" role="group" aria-label="Date grain" data-anfra-control="grain">
          <button class="btn" data-variant="outline" type="button" data-grain="week">Week</button>
          <button class="btn" data-variant="secondary" type="button" data-grain="month" aria-pressed="true">Month</button>
          <button class="btn" data-variant="outline" type="button" data-grain="quarter">Quarter</button>
        </div>
      </header>
      <section><div id="trend" class="chart" data-anfra-query="trend"></div></section>
      <div id="trend-status" class="status"></div>
    </section>
  </div>
</main>

  <script>
    // ---- Design layer: follow the OS light/dark setting (no storage: the frame is sandboxed). ----
    const darkQuery = window.matchMedia('(prefers-color-scheme: dark)');
    const applyTheme = () => document.documentElement.classList.toggle('dark', darkQuery.matches);
    applyTheme();

    function chartTheme () {
      const css = getComputedStyle(document.documentElement);
      const get = (name) => css.getPropertyValue(name).trim();
      return {
        text: get('--chart-text'),
        grid: get('--chart-grid'),
        cat: [1, 2, 3, 4, 5, 6, 7, 8].map((n) => get(`--chart-cat-${n}`)),
      };
    }

    // ---- SDK wiring ----
    const app = Anfra.createApp({ title: 'Sales Overview' });

    const byRegion = app.createQuery('byRegion', {
      dataset: 'ecommerce',
      aql: `
        explore {
          dimensions { region: users.region }
          measures { revenue: orders | sum(orders.amount) }
          sorts { revenue desc }
        }
      `,
    });

    const trend = app.createQuery('trend', {
      dataset: 'ecommerce',
      aql: `
        explore {
          dimensions { period: orders.created_at }
          measures { revenue: orders | sum(orders.amount) }
          sorts { period asc }
        }
      `,
    });

    const region = app.createFilter('region', { dataset: 'ecommerce', field: 'users.region' });
    const dates = app.createFilter('dates', { dataset: 'ecommerce', field: 'orders.created_at' });
    const grain = app.createDateDrill('grain', { default: 'month' });

    app.mapControl(region, byRegion, { field: 'users.region' });
    app.mapControl(region, trend, { field: 'users.region' });
    app.mapControl(dates, byRegion, { field: 'orders.created_at' });
    app.mapControl(dates, trend, { field: 'orders.created_at' });
    app.mapControl(grain, trend, { field: 'orders.created_at' });
    app.mapCrossFilter(byRegion, trend);

    document.getElementById('user').textContent = `Signed in as ${Anfra.user.name}`;

    const CURRENCY = 'USD'; // The dataset's currency: ask the user when the snapshot doesn't say.
    const money = new Intl.NumberFormat(undefined, { style: 'currency', currency: CURRENCY, maximumFractionDigits: 0 });
    const moneyShort = new Intl.NumberFormat(undefined, { style: 'currency', currency: CURRENCY, notation: 'compact', maximumFractionDigits: 1 });
    // Numbers arrive as strings: convert for charts and math, keeping null as a gap (Number(null) is 0).
    const num = (value) => (value == null ? null : Number(value));
    // A period label that follows the grain: "Jan 2026", "Q1 2026", or a week's first day "Jan 5".
    // Read the date part only, in UTC, so the reader's timezone can't shift it to the day before.
    let selectedGrain = 'month';
    let resultGrain = selectedGrain;
    const periodLabel = (value) => {
      const date = new Date(`${String(value).slice(0, 10)}T00:00:00Z`);
      if (resultGrain === 'quarter') return `Q${Math.floor(date.getUTCMonth() / 3) + 1} ${date.getUTCFullYear()}`;
      const parts = resultGrain === 'week' ? { month: 'short', day: 'numeric' } : { month: 'short', year: 'numeric' };
      return date.toLocaleDateString(undefined, { ...parts, timeZone: 'UTC' });
    };
    const byRegionChart = echarts.init(document.getElementById('by-region'));
    const trendChart = echarts.init(document.getElementById('trend'));

    // The four states of a query: loading, error, no rows, success (status stays hidden).
    function renderStatus (query, elementId) {
      const el = document.getElementById(elementId);
      el.replaceChildren();
      if (query.state === 'executing') {
        el.append(Object.assign(document.createElement('div'), { className: 'skeleton' }));
      } else if (query.state === 'error') {
        const alert = Object.assign(document.createElement('div'), { className: 'alert' });
        alert.dataset.variant = 'destructive';
        const noAccess = query.error.name === 'PermissionError';
        const title = document.createElement('h2');
        title.textContent = noAccess ? "You don't have access to this data" : "Couldn't load this chart";
        const detail = document.createElement('section');
        detail.textContent = noAccess ? 'Ask your Holistics admin for access.' : query.error.message;
        alert.append(title, detail);
        el.append(alert);
      } else if (query.state === 'success' && query.result.rows.length === 0) {
        el.append(Object.assign(document.createElement('div'), { className: 'empty', textContent: 'No sales for these filters' }));
      }
      el.classList.toggle('visible', el.childElementCount > 0);
    }

    function axisStyle (theme) {
      return {
        axisLabel: { color: theme.text },
        axisLine: { lineStyle: { color: theme.grid } },
        splitLine: { lineStyle: { color: theme.grid } },
      };
    }

    function render () {
      renderStatus(byRegion, 'by-region-status');
      renderStatus(trend, 'trend-status');
      const theme = chartTheme();

      if (byRegion.result) {
        const rows = byRegion.result.rows;
        const selected = new Set(byRegion.selectedRows.map((row) => row.region));
        // A plain setOption merges into the series the chart has: a click only restyles the bars.
        // Rebuilding the series (replaceMerge) would replay the entry animation on every click.
        byRegionChart.setOption({
          textStyle: { color: theme.text },
          grid: { left: 8, right: 8, top: 16, bottom: 8, containLabel: true },
          tooltip: { valueFormatter: (v) => money.format(v) },
          xAxis: { type: 'category', data: rows.map((row) => row.region), ...axisStyle(theme) },
          yAxis: { type: 'value', axisLabel: { color: theme.text, formatter: (v) => moneyShort.format(v) }, splitLine: axisStyle(theme).splitLine },
          series: [{
            type: 'bar',
            itemStyle: { color: theme.cat[0], borderRadius: [4, 4, 0, 0] },
            data: rows.map((row) => ({
              value: num(row.revenue),
              itemStyle: { opacity: selected.size === 0 || selected.has(row.region) ? 1 : 0.3 },
            })),
          }],
        });
      }

      if (trend.result) {
        // Label by the grain the shown rows came back in, not a grain still loading.
        if (trend.state === 'success') resultGrain = selectedGrain;
        const rows = trend.result.rows;
        trendChart.setOption({
          textStyle: { color: theme.text },
          grid: { left: 8, right: 16, top: 16, bottom: 8, containLabel: true },
          tooltip: { trigger: 'axis', valueFormatter: (v) => money.format(v) },
          xAxis: { type: 'category', data: rows.map((row) => periodLabel(row.period)), ...axisStyle(theme) },
          yAxis: { type: 'value', axisLabel: { color: theme.text, formatter: (v) => moneyShort.format(v) }, splitLine: axisStyle(theme).splitLine },
          series: [{
            type: 'line', smooth: true, showSymbol: false,
            lineStyle: { color: theme.cat[0], width: 2 },
            itemStyle: { color: theme.cat[0] },
            areaStyle: { color: theme.cat[0], opacity: 0.08 },
            data: rows.map((row) => num(row.revenue)),
          }],
        });
      }
    }

    app.subscribe(render);
    darkQuery.addEventListener('change', () => { applyTheme(); render(); });

    // A click toggles that bar in or out of the selection, so a reader can pick several regions.
    byRegionChart.on('click', (params) => {
      const row = byRegion.result.rows[params.dataIndex];
      const selected = byRegion.selectedRows;
      byRegion.select(selected.includes(row)
        ? selected.filter((picked) => picked !== row)
        : [...selected, row]);
      app.execute();
    });

    // Region multi-select. The combobox element is its own instance: refresh(), clear(), setValue().
    // Basecoat's deferred script initializes it on DOMContentLoaded, so wait for that before refresh().
    const regionBox = document.getElementById('region-combobox');
    const regionList = document.getElementById('region-listbox');
    const domReady = document.readyState === 'loading'
      ? new Promise((resolve) => document.addEventListener('DOMContentLoaded', resolve))
      : Promise.resolve();
    Promise.all([region.loadOptions(), domReady]).then(([options]) => {
      regionList.replaceChildren(...options.map((value) => {
        const option = document.createElement('div');
        option.setAttribute('role', 'option');
        option.dataset.value = String(value);
        option.textContent = String(value);
        return option;
      }));
      regionBox.refresh();
    }).catch((err) => console.error('Could not load region options', err));
    regionBox.addEventListener('change', (event) => {
      const values = Array.isArray(event.detail.value) ? event.detail.value : [];
      region.setCondition({ operator: 'is', values });
      app.execute();
    });

    // Date range: two date inputs for a fixed range, or a preset for a rolling one. A preset sends its
    // AQL date phrase, which the server resolves in the workspace timezone, so "last 30 days" stays
    // current in a saved app. Never compute preset dates in the browser.
    const fromInput = document.getElementById('date-from');
    const toInput = document.getElementById('date-to');
    const presets = document.querySelectorAll('[data-range]');
    const allPreset = document.querySelector('[data-range=""]');
    function pressPreset (pressed) {
      presets.forEach((button) => {
        const on = button === pressed;
        button.dataset.variant = on ? 'secondary' : 'outline';
        button.setAttribute('aria-pressed', String(on));
      });
    }
    function applyDateRange () {
      if (fromInput.value && toInput.value) {
        dates.setCondition({ operator: 'between', values: [fromInput.value, toInput.value] });
        pressPreset(null);
      } else {
        dates.setCondition({ operator: 'is', values: [] });
        pressPreset(allPreset);
      }
      app.execute();
    }
    fromInput.addEventListener('change', applyDateRange);
    toInput.addEventListener('change', applyDateRange);
    presets.forEach((button) => {
      button.addEventListener('click', () => {
        fromInput.value = '';
        toInput.value = '';
        const phrase = button.dataset.range;
        dates.setCondition(phrase
          ? { operator: 'matches', values: [phrase] }
          : { operator: 'is', values: [] });
        pressPreset(button);
        app.execute();
      });
    });

    // Grain: a segmented control. The pressed button is the secondary variant.
    document.querySelectorAll('[data-grain]').forEach((button) => {
      button.addEventListener('click', () => {
        document.querySelectorAll('[data-grain]').forEach((other) => {
          const on = other === button;
          other.dataset.variant = on ? 'secondary' : 'outline';
          other.setAttribute('aria-pressed', String(on));
        });
        selectedGrain = button.dataset.grain;
        grain.setGrain(selectedGrain);
        app.execute();
      });
    });

    document.getElementById('clear-selection').addEventListener('click', () => {
      app.clearSelection();
      app.execute();
    });

    window.addEventListener('resize', () => {
      byRegionChart.resize();
      trendChart.resize();
    });

    app.execute();
  </script>
</body>
</html>
```
