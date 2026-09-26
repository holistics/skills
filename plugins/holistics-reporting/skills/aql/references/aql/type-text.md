## Definition
A text value, represented as a string of characters. The "text" type can include any characters, including letters, numbers, symbols, and whitespace.

```aml 
dimension product_name {
  label: "Product Name"
  type: "text"
}
```

## Text Operator 
| Operator | Example | Description |
| --- | --- | --- |
| `==` <br /> <br /> `is`| `products.name == 'Dandelion'` <br /> <br /> `products.name is 'Dandelion'` | Equal to |
| `!=` <br /> <br /> `is not`| `products.name != 'Rock'` <br /> <br />  `products.name is not 'Rock'`| Not equal to | 
| `like` | `products.name like '%Dan'` | Match the pattern specified |
| `not like` | `products.name not like '%Dan'` | Not match the pattern specified |
| `ilike` | `products.name ilike '%dan'` | Match the pattern specified, case insensitive |
| `not ilike` | `products.name not ilike '%dan'` | Not match the pattern specified, case insensitive |
| `is null` | `products.name is null` | Include if the value is null |
| `not null` | `products.name not null` | Include if the value is not null |
| `in` | `products.name in ['Dandelion', 'Rock']` | Include if the value is in the list |
| `not in` | `products.name not in ['Dandelion', 'Rock']` | Include if the value is not in the list |
