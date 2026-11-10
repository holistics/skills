# Writing Viz AML

## From AQL to Viz
* In an AQL explore, `dimensions` are unaggregated, while `measures` are aggregated.
* `func(param1)` is equivalent to `param1 | func()`
* `func(param1, param2, param3)` is equivalent to `param1 | func(param2, param3)`
* `minute()`, `hour()`, `day()`, `week()`, `month()`, `quarter()`, `year()` are date truncation transformations. Convert them into `VizFieldFull.transformation` in this string format: `datetrunc <date_unit>`
* Convert `date_part(unit, field)` into `VizFieldFull.transformation` in this string format: `date_part <date_unit>`

### AQL anatomy
```aql
// Adhoc fields:
metric adhoc_metric_name = ...; // adhoc metric (aka. measure)
dimension model_name.adhoc_dimension_name = ...; // adhoc dimension

// Explore
explore {
  dimensions {
    label1: model_name.dimension_name,
    label2: model_name.dimension_name | month(),
  }
  measures {
    label3: metric_name,
    label4: sum(model_name.dimension_name), // inline metric expression
  }
  filters {
    filter_expression_1,
    filter_expression_2,
  }
  params { // assigns values to dataset params
    model_name.param_name is 'value',
  }
}
```

## Viz fields
### References
A Viz field (`x_axis`, `legend`, `y_axis.series.field`, `rows`, `columns`, `values`, `fields`, `filter.field`, ...) points at a field with one of these syntaxes:

| Syntax | References |
| :----- | :--------- |
| `r(model_name.field_name)` | A dimension defined in a model of the dataset |
| `r(model_name.metric_name)` | A metric/measure defined in a model of the dataset |
| `r(dataset_name.metric_name)` | A metric/measure defined in the dataset itself (without an associated model) |
| `ref('model_name', 'field_name')` | Same target as `r(model_name.field_name)`, written as strings. Because both parts are strings, they can be built dynamically (e.g. from Function inputs) |
| `'metric_name'` | A measure by name. The name is a string, so it can be dynamic too |

**Always prefer `r(...)`**: it's a real identifier, so the compiler resolves it statically and reports a diagnostic when the model or field doesn't exist. String forms (`ref('...', '...')`, `'metric_name'`) are only resolved at runtime, so typos and stale names slip through silently. Use a string form ONLY when `r(...)` cannot express the reference.

Which one to use:
* **Existing dataset field** (listed in the dataset fields): use `r(...)`. Fall back to `ref('model_name', 'field_name')` only when the model/field name isn't known upfront, e.g. inside a Function where it's built from the inputs.
* **Adhoc field or inline expression from the AQL explore**: declare it as a Viz `calculation` FIRST, then reference that calculation by name:
  * dimension calculation -> `ref('model_name', 'calculation_name')`
  * measure calculation -> `'calculation_name'`
* Every reference MUST resolve to either a dataset field or a Viz calculation. AQL explore labels are NOT references.
### Params
**Params** are a third kind of dataset field (`params` in the dataset fields), holding values chosen by the user.
Each param assignment in AQL `explore.params {}` becomes one Viz `filter` block:
```aml
filter {
  field: r(model_name.param_name)
  operator: 'is'
  value: '123'
}
```
Operator mapping from AQL to the Viz `filter` block:

| AQL param assignment | Viz filter |
| :------------------- | :--------- |
| `is x`, `== x` | `operator: 'is'`, `value: x` |
| `is not x`, `!= x` | `operator: 'is_not'`, `value: x` |
| `in [a, b]` | `operator: 'is'`, `value: [a, b]` |
| `not in [a, b]` | `operator: 'is_not'`, `value: [a, b]` |
| `> x`, `< x` | `operator: 'greater_than'` / `'less_than'`, `value: x` |
| `between [a, b]` | `operator: 'between'`, `value: [a, b]` |
| `contains x`, `not contains x` | `operator: 'contains'` / `'does_not_contain'`, `value: x` |
| `starts with x`, `ends with x` | `operator: 'starts_with'` / `'ends_with'`, `value: x` |
| `is null`, `is not null` | `operator: 'is_null'` / `'not_null'` |
| `matches @(time_expression)` | `operator: 'matches'`, `value: '<time_expression>'` (the text inside `@()`, e.g. `value: 'last month'`) |

* Param values can ONLY be **set** in `filter` blocks, **NEVER** in `conditions`. And a param **CANNOT** be used as a viz field (`x_axis`, `legend`, `values`, ...).
* **Reading** a param's values inside a `calculation` formula is fine, e.g. `formula: @aql revenue | where(orders.gender in orders.gender_param);;`
### Conditional formatting
* Conditional formatting is ONLY usable in DataTable and PivotTable.
### Viz field type
* ONLY measures can be placed in `y_axis`, `values`. Dimensions MUST be placed in other viz slots.

## Writing Viz
* Study the dataset fields carefully. Use all details provided in the dataset fields (field name, label, description, type, aql, etc.) to understand their data meanings.
* When converting an AQL explore, do NOT write new AQL. Only move the explore's existing AQL expressions into the Viz.
* You CANNOT reference any labels or metrics/dimensions declared in the AQL explore. You MUST move the AQL expressions into the Viz.
* You MUST only use the properties available in Viz type definition. Do NOT imagine or hallucinate any new properties. Do NOT use properties of one viz type in another viz type if those properties are not available in that viz type's type definition. For example, `single_cell_display` is a property of DataTable, it must NOT be used in PivotTable.
* Apply settings to make the Viz nice and readable.
* Only set explicit `color` (series/mark colors) when the user asks for it — otherwise leave coloring to the default color palette.
* Row limit MUST follow AQL explore's limit.
* If you want to reduce number of legends, use `group_values_into`. E.g. `group_values_into: 10` means there will be maximum 10 legends, the remainings will be grouped into an "Others" group.
* Make sure date fields are always formatted.
* For number fields, if the dataset dimension or measure already has a format, keep the format using `pattern: 'inherited'`, unless requested otherwise. NOTE: **only** number fields may use `pattern: inherited`.
* Keep the AQL granularity by default: every dimension in AQL `explore.dimensions {}` should appear in the Viz.
* When the dimensions don't fit the viz slots, resolve it in this order:
  1. **Change the viz type**, if no viz type was requested and there is no current Viz type to preserve. Choose another viz type that fits all dimensions.
  2. **Fold the dimension into a calculation**, if the result stays readable (e.g. not a long list of IDs in every tooltip, and not so many category values that the Viz no longer matches what the user asked for). Otherwise go to step 3:
     * If the viz type has `tooltips`: add a calculation `string_agg(<dimension>, sep: ', ')` and put it in `tooltips`. NEVER put a raw dimension in `tooltips`; that raises an error.
     * Otherwise: merge it into a kept category field with `concat`, e.g. `concat(products.name, ' (', products.sku, ')')`. Convert non-text fields first with `cast(<dimension>, 'text')`.
     * Do NOT add any calculations other than `string_agg`, `concat` and `cast` for this purpose.
  3. **Drop the dimension.** The measures stay correct because they're recomputed at the Viz's grain. But each category may now combine several values, so choose what to drop carefully:
     * Keep every field the user named.
     * Next, drop dimensions that aren't likely to affect granularity.
     * If you still need to drop more, drop the dimensions least relevant to the user's request.
* Do NOT ask the user to change the AQL just because the dimensions don't fit. Build the Viz and tell the user which dimensions you folded or dropped, and why.
* Ask the user to clarify only when none of the steps above can produce a Viz that shows what the user asked for. For example, a measure the user asked for is missing from the AQL explore, or the requested viz type has no slot for a field the user explicitly named. Having to fold or drop dimensions the user didn't name is NOT a reason to clarify.
### Steps
1. Preserve existing Viz calculations from current Viz
2. Convert **ALL** adhoc fields (adhoc dimensions + adhoc metrics, declared in the AQL `dimension <model_name.dim_name> =` and `metric <metric_name> =` statements) and inline metric expressions  into Viz `calculation`s
  * VERY VERY IMPORTANT: Do **NOT** specify `model` when declaring adhoc **metrics** in Viz calculations
  * Calculation names must NOT be the same with existing dimension/measure names in the dataset
3. Choose the most suitable viz type and allocate the dimensions and measures into proper viz fields
4. Convert explore filters into Viz `condition`s, and explore params into Viz `filter` blocks
5. Double-check that you are using valid references: All references **MUST** exist in
  * Dataset fields
  * Or Viz calculations
6. Configure settings for viz fields (e.g. formatting, conditional formatting, colors, etc.)
7. Configure settings for the viz (e.g. row limit, series style, etc.)
8. Review

## Viz guidelines
* Carefully study user's current Viz AML, if provided. Preserve viz type, formats, etc of existing Viz whenever appropriate.
* Legend breaks down X Axis. Hence, Legend field should be more granular than X Axis field. E.g. If there are "Country" and "City", "Country" should be X Axis and "City" should be Legend.
