---
name: build-data-app
description: Build or change a Holistics Data App, one self-contained HTML file pasted into the Data App editor that queries the user's datasets through the `Anfra` SDK global and renders them with its own HTML, CSS and JS. Starts from the description and data snapshot the in-app guide gives, or collects them when the user comes here directly, then iterates on the user's test feedback.
---

# Building a Data App

A **Data App** is one self-contained HTML file the user pastes into the Holistics Data App editor.
It runs in a sandboxed frame where the SDK is already on the global `Anfra`. The SDK supplies
data and state; every pixel is yours. You never run the app yourself: the user runs it and reports
back, so their console and the editor's Inspect panel are your only debuggers.

References, read when a step needs them:

- [api.md](references/api.md): every SDK call, the result shape, page structure and errors. **Read it before
  writing any code; do not invent APIs.** Only the core SDK is available: no export, render or
  lineage.
- [aql](../aql/) skill: writing the query bodies.
- [example.html](references/example.html): a complete app in the default Holistics look. Start the file from its
  skeleton.

## 1. Collect the datasets and the idea

You need the **datasets** the app may use (their fields and metrics) and a **description** of the
app. The invocation may hold a data snapshot, a description, both or neither, so check before
asking. A snapshot is JSON with `user` and `datasets`; when one is there, use it, and the rest of
the invocation is the description.

1. **No description:** ask what the app should show and who it's for, in one short question. Don't
   suggest app ideas unless the user asks for them.
2. **No snapshot, Holistics MCP server connected:** read the datasets through it rather than asking
   for a snapshot, which saves the user copying code and JSON back and forth.
   1. With the description in hand, call `list_datasets` and shortlist the datasets that fit. Skip
      ones tagged `Archived` or `Deprecated` or similar.
   2. In one message, show the shortlist, name the server, and ask the user to confirm both the
      datasets and that the app will live in that server's workspace (it may point at a different
      one).
   3. Call `fetch_dataset` for each. Its `relationships` show which models join, and its
      descriptions carry the modeler's caveats on grain, fan-out and which date to use: follow
      them.
3. **No snapshot and no MCP server**, or the server points at another workspace: ask for the
   snapshot. Send the user this message as written, with the script right under the message's
   step 2 so it sits next to the step that uses it:

   > 1. Open a Data App in the workspace the app will live in, or create one,
   >    and click **Edit app**.
   >    <!-- TODO: add the docs link after "create one": ([guide](<docs link>)) -->
   > 2. Replace everything in the **Code** tab with this script, then select **Update preview**.
   >
   >    ```html
   >    <pre id="out" style="white-space:pre-wrap"></pre>
   >    <script>
   >      const summary = {
   >        user: Anfra.user,
   >        datasets: Object.fromEntries(Object.entries(Anfra.datasets).map(([uname, d]) => [uname, {
   >          label: d.label,
   >          models: Object.fromEntries(d.data_models.map((m) => [m.name,
   >            m.fields.map((f) => `${f.name}: ${f.type}${f.is_custom_measure ? ' (measure)' : ''}`)])),
   >          metrics: d.metrics.map((m) => `${m.name}: ${m.type}`),
   >        }])),
   >      };
   >      document.getElementById('out').textContent = JSON.stringify(summary, null, 2);
   >    </script>
   >    ```
   >
   > 3. Copy the JSON that appears and paste it here.
   >
   > Tips:
   >
   > - If you already know which datasets the app needs, delete the others before pasting.
   > - If you already know what the app should show and who it's for, include that with the JSON.

Whichever source you use:

- A dataset's key (`uname` from MCP) is what `dataset:` takes.
- A field is `model.field` (`orders.created_at`); a dataset metric is its bare name.
- A field marked `(measure)` in the snapshot is a measure (`orders.total_revenue`); the
  [aql](../aql/) skill covers how to use one.
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
   - **Entities:** every `createQuery` (dataset, dimensions, measures), `createFilter`,
     `createDateDrill`, `mapControl` and `mapCrossFilter`, using only names that appear verbatim
     in the environment or are declared query-local in the AQL.
   - **Rendering:** chart or table per query (default ECharts 6 from jsDelivr, as in the example).
   - **Cross-filtering:** which clicks filter which queries (same dataset only), and whether they
     replace the selection or toggle rows (see [api.md](references/api.md#cross-filtering)).
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

Write the app as one HTML document the user will paste whole into the Data App's **Code** tab.
Follow the example's skeleton: declare everything, `subscribe` a render function, `execute()`, then
wire controls and clicks to set state and `execute()` again. Keep the look (styles, markup, chart
theme) apart from the SDK wiring.

**Queries.** Write each `aql` with the [aql](../aql/) skill. The SDK applies the reader's state (filters,
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
  crossorigin="anonymous"`, as in the example. Copy a file's hash from its jsDelivr page, and never
  guess one: a wrong hash blocks the file. If you can't look a hash up, use only the libraries and
  versions in the example. Load fonts from `@fontsource` on jsDelivr, as the example does: Google
  Fonts' CSS differs per browser, so it can't be hashed.
- The app is its one HTML file: no relative `src` or `href`. Inline your scripts and styles, and
  images as SVG or a `data:` URI.
- `localStorage`, `sessionStorage` and cookies throw: keep state in variables, and follow
  `prefers-color-scheme` rather than Basecoat's theme switcher, which stores the mode.
- Forms, popups, navigation, `<iframe>` and `<base>` are blocked: use buttons and `change`
  listeners, never `<form>`.

**Structure.** Mark the page as [api.md](references/api.md#structure) shows: `data-anfra-container`
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

Serialize the metadata as JSON, escaping every `<` as the literal JSON escape `\u003c` so prompt
text cannot close the script tag. Keep the block static, with no runtime script to populate it.
When editing an older file, add missing fields using these rules; an unknown original creation
time stays `null`.

Done when the file holds every entity from the agreed list, every part is marked, each query
renders all four states, every CDN asset carries its hash, the example's error banner script is kept,
and the metadata block has all five fields with known values or explicit `null`s.

## 4. Hand over and iterate

You can't run the app against the user's data, so check every name against the environment before
handing over.

**Hand over a file, not only a code block.** A long code block copied out of a terminal or chat can
lose or break lines, and a damaged paste leaves a blank or half-styled page. When you can write
files, save the app as one `.html` file and give its full path. Where a clipboard command exists
(`pbcopy` on macOS, `clip` on Windows, `wl-copy` or `xclip -selection clipboard` on Linux), also put
the file on the clipboard and say so. Give the whole file in one code block only when you can't
write files.

When a browser is available to you (headless Chrome, Playwright), render the file once before
handing over, with a stub `Anfra` built from the snapshot or the MCP datasets: their `datasets`
and `user`, and a `createApp` whose queries return one made-up row. That catches syntax errors,
crashes and broken layout. It says nothing about the AQL, which only the real SDK checks.

Then give the user these steps: in the Data App, click **Edit app**, replace everything in the
**Code** tab with the file, select **Update preview**, and try every control and click. Select
**Save** whenever it looks right; they can keep refining after saving.

Tell them, in their terms, what the page shows and how to use each control, the assumptions you
made, and that you could not run it yourself. Ask them to check one headline number against one
they trust. If anything is off, ask for:

- what they see, against what they expected;
- the console panel contents;
- for a query that errored or looks wrong, its entry in the editor's Inspect panel (state,
  executed AQL, error), and any problems the panel shows on the structure tree.

A page that shows its static markup but nothing the script fills in (placeholder text, no rows,
half the styles) means the script never ran, almost always a damaged paste. The error banner from
the example names the line where the parser noticed, usually at or just after the damage. Ask the
user to paste again from the file or clipboard, and to compare the **Code** tab's last line number
with the file's line count.

Read their report against [api.md](references/api.md#errors): a `ValidationError` names a declaring
line; a `QueryError` carries the server's message about the AQL, or names the bad entry
(`filters[0].field`). Compare a misbehaving query's executed AQL with what you meant. A query
marked "Not drawn yet" has no element marked with it. When the user names a part by its handle
(`data-anfra-block="trend"`), search the file for that attribute: it is the element they mean.

Change the smallest thing that explains the problem, and restate a change first if it alters what a
number means. Return the whole updated file the same way as the first (saved file, clipboard and path;
a code block only when you can't write files), never a diff or a snippet, since the user replaces
the whole **Code** tab. Preserve `prompt` and `createdAt`, refresh `model`, `effort` and
`updatedAt`, and repeat until the user says it's done.
