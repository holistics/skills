# Data format
A format is a pattern string on a viz field's `format` block. Below are the common cases. For anything else (the standard currency list, the full syntax), search the docs for number formats or date formats.

## Date patterns
Parts: `dd` day, `LL` month as a number, `LLL` month abbreviated, `yyyy` year. Separate them with
`-`, `/`, `,` or a space.

| Pattern | Renders as |
| --- | --- |
| dd/LL/yyyy | 08/02/2000 |
| LLL dd, yyyy | Jan 01, 2022 |
| LLL yyyy | Jan 2022 |
| yyyy | 2022 |

Match the pattern to the field's granularity: a dimension carrying `transformation: 'datetrunc month'` should use `LLL yyyy`, not a pattern with a day part.

## Number patterns
The parts always appear in this order:
```
<currency_prefix><integer><fraction><percentage><abbreviation><currency_suffix>
```

* **currency**: `[$<symbol>]`, at the start or the end of the pattern. Any symbol works, e.g. `[$$]`, `[$€]`, `[$m]`, `[$₿]`.
* **integer**: `#,###` to group thousands.
* **fraction**: `0.0`, with one more `0` per decimal place.
* **percentage**: `%` multiplies the value by 100 and appends the symbol; `\\%` appends the symbol
  and leaves the value alone.
* **abbreviation**: `,"K"`, `,,"M"`, `,,,"B"`, or `"A"` to pick the unit from the value. The commas are part of the syntax.

Percentage cannot be combined with a currency or an abbreviation.

Separators are not part of the pattern. They are sibling properties of the `format` block, and on a viz field they are snake_case: `group_separator` (default `,`, also accepts `.` or a space) and `decimal_separator` (default `.`, also accepts `,`). Set both when a request calls for a non-default convention, e.g. `1.234.567,89`:
```aml
format {
  type: 'number'
  pattern: '#,###0.00'
  group_separator: '.'
  decimal_separator: ','
}
```

| Pattern | 124412.4 renders as |
| --- | --- |
| #,###0 | 124,412 |
| #,###0.00 | 124,412.40 |
| #,###,"K" | 124K |
| #,###0.000,,"M" | 0.124M |
| [$$]#,###0 | $124,412 |
| #,###0.0\\% | 124412.4% |