# Data format
## Date format
A Date format consists of:
* Day part:
  * `dd` (e.g. 01, 12)
* Month part:
  * `LL`: Numeric value (e.g. 08, 12)
  * `LLL`: Three-letter abbreviation (e.g. Aug, Dec)
* Year path:
  * `yyyy` (e.g. 1990, 2012)
* Seperators:
  * `-`
  * `/`
  * ` ` (space)

Examples:
| Date Patterns | Example |
| --- | --- |
| dd/LL/yyyy or dd-LL-yyyy | 08/02/2000 or 08-02-2000 |
| LL/dd/yyyy or LL-dd-yyyy | 12/13/2022 or 12-13-2022 |
| LLL dd yyyy | Jan 01 2022 |
| LLL dd, yyyy | Jan 01, 2022 |
| dd LLL, yyyy | 12 Jan, 2002 |

## Number format
A Number format consists of:
```
<currency_prefix><integer><fraction><percentage><abbreviation><currency_suffix>
```

* currency (either prefix or suffix): `[$<currency_symbol>]`
  * Supported currency symbols:
    * `$`: $ US Dollar / MEX Peso
    * `€`: € Euro
    * `¥`: ¥ Yen
    * `£`: £ Pound
    * `元`: 元 Renminbi
    * `₺`: ₺ Lira
    * `₩`: ₩ Won
    * `₽`: ₽ RUS Ruble
    * `₹`: ₹  IND Rupee
    * `₨`: ₨ PAK Rupee
    * `₱`: ₱ PHL Peso
    * `A$`: A$ AUS Dollar
    * `C$`: C$ CAN Dollar
    * `S$`: S$ SGP Dollar
    * `NZ$`: NZ$ NZ Dollar
    * `HK$`: HK$ HK Dollar
    * `₪`: ₪ Shekel
    * `R$`: R$ Real
    * `฿`: ฿  Thai Baht
    * `R`: R South African Rand
    * `Fr`: Fr Franc
    * `kr`: kr Krona / Krone
    * `Ft`: Ft Forint
    * `Rp`: Rp Rupiah
    * `RM`: RM Ringgit
    * `VND`: VND VN Dong
    * `Tk`: Tk BGD Taka
* integer:
  * Only support `#,###` **exactly**
  * Use `group_separator` and `decimal_separator` to customize
* fraction: `0.0` (add more 0 if more decimal places are needed)
* percentage:
  * Supported formats:
    * `%`: converts a number to percentage format by **multiplying the original value** by 100 and adding "%" symbol
    * `\\%`: onverts a number to percentage format **without modifying the original value** by adding "%" symbol
* abbreviation:
  * Supported formats:
    * `,"K"`
    * `,,"M"`
    * `,,,"B"`
  * Notes:
    * The commas `,` are required as part of the format syntax

NOTEs:
* `<abbreviation>`/`<currency>` CANNOT be used with `<percentage>`

Examples:
| Raw Value | Number Pattern | Displayed as |
| --- | --- | --- |
| 54 | [$$]#,### | $54 |
| 1236 | #,###[$€] | 1,236€ |
| 123456789.0123 | 0.00 | 123456789.01 |
| 12.3456 |	#,###0.0%	| 1,234.6% |
| 12.3456 |	#,###0.0\\%	| 12.3% |
| 124412.4 | '#,###0.000,,"M"' | 0.124M |
| 124412.4 | '#,###0.000,"K"' | 124.412K |
| 124412.4 | '#,###,"K"' | 124K |
| 124412.4 | '#,###0.000,,"M"' | 0.124M |

# Data format in visualizations
* For number fields, if the dataset dimension or measure already has a format, keep the format using `pattern: 'inherited'`, unless requested otherwise. NOTE: **only** number fields may use `pattern: inherited`.
