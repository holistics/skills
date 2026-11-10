### coalesce

```aml
coalesce(val1, val2, ...)
```

```aml title="Examples"
coalesce(users.yearly_payment, users.quarterly_payment, 0)
```

**Description**

This function returns the first non-null value in a list

**Return type**

Vary

**Sample Usages**

Given an AQL expression as below:
```aml
coalesce(yearly_payment, quarterly_payment, monthly_payment)
```

The result would be:  

| Name  | Yearly Payment | Quarterly Payment | Monthly Payment | Payment (coalesce) |
| ----- | -------------- | ----------------- | --------------- | ------------------ |
| Alice | 70.00          | NULL              | NULL            | 70.00              |
| Billy | NULL           | 35.00             | NULL            | 35.00              |
| Conte | NULL           | NULL              | 6.00            | 6.00               |


---

### nullif

```aml
nullif(val1, val2)
```

```aml title="Examples"
nullif(sales_target, sales_current)
```

**Description**

This function returns NULL if two expressions are equal, otherwise it returns the first expression.

**Return type**

Vary

**Sample Usages**

Given an AQL expression as below:
```aml
nullif(sales_target, sales_current)
```

The result would be:  

| Sales Person | Sales Target | Sales Current | Target to be achieved (nullif) |
| ------------ | ------------ | ------------- | ------------------------------ |
| Andy         | 10,000       | 10,000        | null                           |
| Billy        | 23,000       | 18,000        | 23,000                         |
| Cindy        | 21,000       | 21,000        | null                           |
| Danny        | 0            | 10,000        | 0                              |

---

### safe_divide

```aml
safe_divide(dividend, divisor)
```

```aml title="Examples"
safe_divide(total_sales, count_orders)
```

**Description**

Equivalent to the division operator (X / Y), but returns NULL if divisor is 0.

**Return type**

Vary
