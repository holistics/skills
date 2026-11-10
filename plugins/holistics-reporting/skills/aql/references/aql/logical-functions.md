Logical functions return value based on some logical conditions.


### case when
```aml
case(when: condition_expression, then: value_expression, else: value_expression)
```

```aml title="Examples"
case(when: users.gender == 'm', then: 'male') // else: null

case(
  when: users.gender == 'm', then: 'male',
  when: users.gender == 'f', then: 'female',
  else: 'others'
)
```

**Description**

The CASE statement goes through conditions and returns a value when the first condition is met (like an IF-THEN-ELSE statement).

**Return type**

Vary

**Sample Usages**

Given an AQL expression as below:

```aml
case(
  when: users.gender == 'm', then: 'male',
  when: users.gender == 'f', then: 'female',
  else: 'others'
)
```

And the result would be:

| gender | case   |
| ------ | ------ |
| m      | male   |
| f      | female |
| m      | male   |

You can also use unicode within a CASE statement to make your metric returns emoji:

```aml
case(
  when: count(orders.id) > 10
  , then: '✅'
  , else:  cast(count(orders.id), 'text')
)
```

When used with the gender dimension, the above expression result in:

| gender | order_count  |
| ------ | ------ |
| m      | ✅   |
| f      | 5 |
| m      | ✅   |


---

### and
```aml
  and(condition_expression, ...)
```

```aml title="Examples"
and(products.id >= 2, products.id <= 8)
and(products.id >= 2, products.id <= 8, products.id != 5)
```


**Description**

Logical AND compares between multiple [Truefalse](/reference/aql/type-truefalse) expressions and returns true when all expressions are true.

**Return type**

Truefalse

**Example**

Given an AQL expression as below:

```aml
and(products.id >= 2, products.id <= 8)
```

And the result would be:  

| id  | and   |
| --- | ----- |
| 1   | false |
| 2   | true  |
| 8   | true  |
| 9   | false |


--- 

### or

```aml
or(condition_expression, ...)
```

```aml title="Examples"
or(products.id <= 2, products.id >= 8)
or(products.id <= 2, products.id >= 8, products.id != 5)
```

**Description**

Logical OR compares between multiple [Truefalse](/reference/aql/type-truefalse) expressions and returns true when at least one expression is true.

**Return type**

Truefalse

**Sample Usages**

Given an AQL expression as below:

```
or(products.id <= 2, products.id >= 8)
```

And the result would be:  

| id  | or    |
| --- | ----- |
| 1   | true  |
| 4   | false |
| 7   | false |
| 9   | true  |

---

### not

```aml
not(condition_expression)
```

```aml title="Examples"
not(products.id <= 2)
```

**Description**

Logical NOT takes a single [Truefalse](/reference/aql/type-truefalse) expression and returns true when the expression is false.

**Return type**

Truefalse

**Sample Usages**

Given an AQL expression as below:

```
not(is(products.id, null))
```

And the result would be:

| id  | not   |
| --- | ----- |
| 1   | true  |
|     | false |
| 3   | true  |
| 4   | true  |

--- 

### is
:::warning
This function was deprecated in favor of the [is](/reference/aql/operator) operator and only kept for backward compatibility with [Business Calculation](/docs/business-calculation). Please use the operator instead.
:::

```aml
is(field_expression, value_expression)
```

```aml title="Examples"
is(products.id, null)
```

**Description**

Logical IS evaluates the given statement and return either `true` or `false`. 

**Return type**

Truefalse

**Sample Usages**

Given an AQL expression as below:

```
is(products.id, null)
```

And the result would be:

| id  | not   |
| --- | ----- |
| 1   | false  |
|     | true |
| 3   | false  |
| 4   | false  |

--- 


### in

:::warning
This function was deprecated in favor of the [in](/reference/aql/operator) operator and only kept for backward compatibility with [Business Calculation](/docs/business-calculation). Please use the operator instead.
:::

```aml
in(field_expression, value_expression, value...)
```

```aml title="Examples"
in(users.name, 'bob', 'alice', 'jack')
```

**Description**

`in` operator takes a field expression and a list of values. Return true if that list of values contains the value of that field expression.

**Return type**

Boolean

**Sample Usages**

Given an AQL expression as below:

```
in(users.name, 'bob', 'alice', 'jack')
```

And the result would be:

| name  | in    |
| ----- | ----- |
| bob   | true  |
| alice | true  |
| peter | false |
